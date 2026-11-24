//! The European Nucleotide Archive through its Portal and Browser APIs.

import 'dart:io';
import 'dart:math';

import 'package:segui/services/databases/archive.dart';
import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/types.dart';

class EnaArchive extends SequenceArchive {
  const EnaArchive(super.client);

  /// The Portal has no offset, so more results mean a larger limit.
  static const int pageSize = 100;
  static const int maxResults = 500;

  /// A pasted genome or study can list thousands of records.
  static const int _maxLookUp = 5000;

  static const String _host = 'www.ebi.ac.uk';
  static final RegExp _assemblyAccession = RegExp(r'^GCA_\d{9}$');

  // INSDC accessions have no underscore, unlike RefSeq.
  static final RegExp _sequenceAccession = RegExp(r'^[A-Z]{1,6}\d{5,}$');

  @override
  DatabaseSource get source => DatabaseSource.ena;

  @override
  int get batchSize => 50;

  @override
  Future<DatabasePage> search(
    DatabaseQuery query, {
    PageCursor? after,
    CancelToken? cancel,
  }) async {
    if (query.organism.trim().isEmpty) {
      throw const DatabaseException('Enter an organism to search ENA.');
    }
    final int taxId = after?.taxId ?? await _taxId(query.organism, cancel);
    final int limit = min(after?.offset ?? pageSize, maxResults);
    final String result = _result(query.content);
    final String terms = buildQuery(query, taxId);
    final countRequest = _count(result, terms, cancel);
    final rows = await _rows({
      'result': result,
      'query': terms,
      'fields': _fields(query.content),
      'limit': '$limit',
    }, cancel);
    final records = await _withOrganisms(
      _records(rows, query.content),
      rows,
      cancel,
    );
    final bool hasAll = rows.length < limit;
    final int total =
        hasAll ? records.length : max(await countRequest, rows.length);
    return DatabasePage(
      records: records,
      total: total,
      next: !hasAll && limit < maxResults
          ? PageCursor(
              offset: min(limit + pageSize, maxResults),
              taxId: taxId,
            )
          : null,
    );
  }

  @override
  Future<DatabasePage> lookUp(
    List<String> accessions,
    DownloadContent content, {
    CancelToken? cancel,
  }) async {
    final List<DatabaseRecord> records = [];
    final Set<String> found = {};
    void keep(DatabaseRecord record, String requested) {
      found.add(requested);
      if (!records.any((e) => e.key == record.key)) records.add(record);
    }

    switch (content) {
      case DownloadContent.reads:
        // A study, sample, or experiment lists its runs; fetch 4 concurrently.
        for (final List<String> chunk in batches(accessions, 4)) {
          final results = await Future.wait([
            for (final String accession in chunk)
              _rowsOrNone({
                'accession': accession,
                'result': 'read_run',
                'fields': _fields(content),
              }, cancel, endpoint: 'filereport')
                  .then((rows) => (accession: accession, rows: rows)),
          ]);
          for (final item in results) {
            for (final record in _records(item.rows, content)) {
              keep(record, item.accession);
            }
          }
        }
      case DownloadContent.coding:
        // A protein ID names one coding sequence, and a nucleotide
        // accession names all the coding sequences in it.
        for (final List<String> batch in batches(accessions, batchSize)) {
          final String query = batch
              .map(baseAccession)
              .expand((id) => ['accession="$id"', 'parent_accession="$id"'])
              .join(' OR ');
          final rows = await _rowsOrNone({
            'result': _result(content),
            'query': query,
            'fields': _fields(content),
          }, cancel);
          final named = await _withOrganisms(
            _records(rows, content),
            rows,
            cancel,
          );
          final Map<String, DatabaseRecord> recordOf = {
            for (final record in named) baseAccession(record.accession): record,
          };
          for (final row in rows) {
            final record = recordOf[baseAccession(_text(row['accession']))];
            if (record == null) continue;
            for (final String accession in batch) {
              if (accessionMatches(accession, record.accession) ||
                  baseAccession(accession) ==
                      baseAccession(_text(row['parent_accession']))) {
                keep(record, accession);
              }
            }
          }
        }
      case DownloadContent.nucleotide || DownloadContent.assembly:
        // ENA rejects a whole request for one accession of the wrong kind.
        final RegExp kind = content == DownloadContent.assembly
            ? _assemblyAccession
            : _sequenceAccession;
        final valid =
            accessions.where((e) => kind.hasMatch(baseAccession(e))).toList();
        for (final List<String> batch in batches(valid, batchSize)) {
          final rows = await _rowsByAccession(
            batch.map(baseAccession).toSet().toList(),
            content,
            cancel,
          );
          for (final record in _records(rows, content)) {
            for (final String accession in batch) {
              if (accessionMatches(accession, record.accession)) {
                keep(record, accession);
              }
            }
          }
        }
      case DownloadContent.protein:
        throw const DatabaseException('ENA has no proteins. Use GenBank.');
    }
    return DatabasePage(
      records: records,
      total: records.length,
      missing: accessions.where((e) => !found.contains(e)).toList(),
    );
  }

  @override
  Future<List<String>> suggestOrganisms(
    String text, {
    CancelToken? cancel,
  }) async {
    final String term = cleanTerm(text).replaceAll('/', ' ');
    if (term.isEmpty) return const [];
    // The suggestions can leave out the exact match, such as a species
    // under its viruses, so that is looked up too.
    final responses = await Future.wait([
      client.read(_taxonomy('any-name', term), cancel: cancel),
      client.read(
        _taxonomy('suggest-for-search', term, {'limit': '8'}),
        cancel: cancel,
      ),
    ]);
    return {
      for (final response in responses)
        if (response.isOk)
          for (final taxon in _objects(decodeArchiveJson(response.body)))
            if (_text(taxon['scientificName']).isNotEmpty)
              _text(taxon['scientificName']),
    }.take(8).toList();
  }

  @override
  Future<RawFasta> saveFasta(
    List<DatabaseRecord> records,
    File destination, {
    CancelToken? cancel,
    void Function(int bytes)? onReceived,
  }) async {
    final String ids =
        records.map((record) => baseAccession(record.accession)).join(',');
    final Uri url = Uri.https(_host, '/ena/browser/api/fasta/$ids');
    await client.save(
      url,
      destination,
      cancel: cancel,
      onReceived: onReceived,
    );
    return RawFasta(file: destination, url: url);
  }

  @override
  FastaOrigin readHeader(String header) {
    final List<String> parts = header.split(RegExp(r'\s')).first.split('|');
    return FastaOrigin(accession: parts.last);
  }

  /// Every sequence of an assembly. ENA adds the contigs that chromosomes
  /// and scaffolds are built from, so see [assemblyReportUrl].
  static Uri assemblyFastaUrl(String accession) {
    return Uri.https(
      _host,
      '/ena/browser/api/fasta/$accession',
      {'download': 'true'},
    );
  }

  /// The list of sequences that make up an assembly. Assemblies without
  /// one have no extra sequences in their FASTA.
  static Uri assemblyReportUrl(String accession) {
    final String root = baseAccession(accession);
    return Uri.https(
      'ftp.ebi.ac.uk',
      '/pub/databases/ena/assembly/${root.substring(0, min(7, root.length))}/'
          '${root.substring(0, min(10, root.length))}/'
          '${accession}_sequence_report.txt',
    );
  }

  /// The Portal query of [query] for the taxon [taxId] and those below it.
  static String buildQuery(DatabaseQuery query, int taxId) {
    final DownloadContent content = query.content;
    final String gene = cleanTerm(query.gene);
    final String keyword = cleanTerm(query.keyword);
    final String keywordField = switch (content) {
      DownloadContent.reads => 'experiment_title',
      DownloadContent.assembly => 'assembly_title',
      _ => 'description',
    };
    final bool hasLength = content != DownloadContent.reads;
    return [
      'tax_tree($taxId)',
      if (gene.isNotEmpty && content == DownloadContent.coding)
        'gene="$gene"'
      else if (gene.isNotEmpty && content == DownloadContent.nucleotide)
        // Sequence records have no gene field.
        'description="$gene"',
      // A plain phrase is a text search. With wildcards ENA is many times
      // slower and finds nothing for phrases.
      if (keyword.isNotEmpty) '$keywordField="$keyword"',
      if (hasLength && query.minLength != null)
        'base_count>=${query.minLength}',
      if (hasLength && query.maxLength != null)
        'base_count<=${query.maxLength}',
    ].join(' AND ');
  }

  Future<int> _taxId(String organism, CancelToken? cancel) async {
    final int? typed = int.tryParse(organism.trim());
    if (typed != null) return typed;
    final String name = cleanTerm(organism).replaceAll('/', ' ');
    final response =
        await client.read(_taxonomy('any-name', name), cancel: cancel);
    final bool isUnknown = response.status == HttpStatus.notFound ||
        response.status == HttpStatus.badRequest;
    if (!response.isOk && !isUnknown) {
      throw DatabaseException(
        'ENA is unavailable (${response.status}). Try again later.',
      );
    }
    final taxa = isUnknown
        ? const <Map<String, Object?>>[]
        : _objects(decodeArchiveJson(response.body));
    final int? id = taxa.isEmpty ? null : _asInt(taxa.first['taxId']);
    if (id == null) {
      throw DatabaseException('No organism is named "$name".');
    }
    return id;
  }

  /// The number of matches, or zero when ENA does not answer. A failed
  /// count must not fail the search.
  Future<int> _count(String result, String query, CancelToken? cancel) async {
    try {
      final response = await client.read(
        _portal('count'),
        form: {'result': result, 'query': query, 'format': 'json'},
        cancel: cancel,
      );
      if (!response.isOk) return 0;
      final Object? json = decodeArchiveJson(response.body);
      return json is Map ? _asInt(json['count']) ?? 0 : 0;
    } on Exception {
      return 0;
    }
  }

  Future<List<Map<String, Object?>>> _rows(
    Map<String, String> form,
    CancelToken? cancel,
  ) async {
    final response = await client.read(
      _portal('search'),
      form: {...form, 'format': 'json'},
      cancel: cancel,
    );
    if (response.status == HttpStatus.noContent) return const [];
    if (!response.isOk) {
      throw DatabaseException(
        'ENA could not run the search (${response.status}). '
        'Try fewer terms, or try again later.',
      );
    }
    if (response.body.trim().isEmpty) return const [];
    return _objects(decodeArchiveJson(response.body));
  }

  /// Like [_rows], but accessions of the wrong kind, which ENA rejects,
  /// count as not found.
  Future<List<Map<String, Object?>>> _rowsOrNone(
    Map<String, String> params,
    CancelToken? cancel, {
    String endpoint = 'search',
  }) async {
    final bool isReport = endpoint == 'filereport';
    final Map<String, String> all = {
      ...params,
      'format': 'json',
      if (!isReport) 'limit': '$_maxLookUp',
    };
    final response = await client.read(
      isReport
          ? _portal(endpoint).replace(queryParameters: all)
          : _portal(endpoint),
      form: isReport ? null : all,
      cancel: cancel,
    );
    if (response.status >= HttpStatus.internalServerError) {
      throw DatabaseException(
        'ENA is unavailable (${response.status}). Try again later.',
      );
    }
    if (!response.isOk || response.body.trim().isEmpty) return const [];
    return _objects(decodeArchiveJson(response.body));
  }

  /// Looks up [accessions], splitting a batch that ENA rejects so one bad
  /// accession does not hide the others.
  Future<List<Map<String, Object?>>> _rowsByAccession(
    List<String> accessions,
    DownloadContent content,
    CancelToken? cancel,
  ) async {
    final response = await client.read(
      _portal('search'),
      form: {
        'result': _result(content),
        'includeAccessions': accessions.join(','),
        'fields': _fields(content),
        'limit': '$_maxLookUp',
        'format': 'json',
      },
      cancel: cancel,
    );
    if (response.status == HttpStatus.badRequest) {
      if (accessions.length == 1) return const [];
      final int middle = accessions.length ~/ 2;
      return [
        ...await _rowsByAccession(
            accessions.sublist(0, middle), content, cancel),
        ...await _rowsByAccession(accessions.sublist(middle), content, cancel),
      ];
    }
    if (response.status == HttpStatus.noContent) return const [];
    if (!response.isOk) {
      throw DatabaseException(
        'ENA is unavailable (${response.status}). Try again later.',
      );
    }
    if (response.body.trim().isEmpty) return const [];
    return _objects(decodeArchiveJson(response.body));
  }

  /// Coding sequences often lack an organism, which their parent record
  /// has. Names are optional, so a failed lookup leaves them empty.
  Future<List<DatabaseRecord>> _withOrganisms(
    List<DatabaseRecord> records,
    List<Map<String, Object?>> rows,
    CancelToken? cancel,
  ) async {
    if (!records.any((record) =>
        record.content == DownloadContent.coding && record.organism.isEmpty)) {
      return records;
    }
    final Map<String, String> parentOf = {
      for (final row in rows)
        if (_text(row['scientific_name']).isEmpty)
          baseAccession(_text(row['accession'])):
              baseAccession(_text(row['parent_accession'])),
    };
    final List<String> parents =
        parentOf.values.toSet().where(_sequenceAccession.hasMatch).toList();
    final Map<String, String> organismOf = {};
    try {
      for (final batch in batches(parents, maxResults)) {
        final found = await _rowsByAccession(
          batch,
          DownloadContent.nucleotide,
          cancel,
        );
        for (final row in found) {
          organismOf[baseAccession(_text(row['accession']))] =
              _text(row['scientific_name']);
        }
      }
    } on DatabaseException {
      return records;
    }
    return [
      for (final record in records)
        if (organismOf[parentOf[baseAccession(record.accession)]]
            case final String organism)
          record.withOrganism(organism)
        else
          record,
    ];
  }

  List<DatabaseRecord> _records(
    List<Map<String, Object?>> rows,
    DownloadContent content,
  ) {
    final List<DatabaseRecord> records = [];
    for (final row
        in content == DownloadContent.assembly ? _latestVersions(rows) : rows) {
      final bool isRun = content == DownloadContent.reads;
      final String id = _text(row[isRun ? 'run_accession' : 'accession']);
      if (id.isEmpty) continue;
      final String version = _text(row[content == DownloadContent.assembly
          ? 'version'
          : 'sequence_version']);
      records.add(DatabaseRecord(
        source: source,
        content: content,
        accession:
            isRun || version.isEmpty || id.contains('.') ? id : '$id.$version',
        organism: _text(row['scientific_name']),
        title: _title(row, content),
        length: isRun ? null : _asInt(row['base_count']),
        codonStart: _asInt(row['codon_start']) ?? 1,
        gene: _text(row['gene']),
        files: isRun ? parseRunFiles(row) : const [],
      ));
    }
    return records;
  }

  /// ENA lists each version of an assembly, but serves only the latest.
  List<Map<String, Object?>> _latestVersions(
    List<Map<String, Object?>> rows,
  ) {
    final Map<String, Map<String, Object?>> latest = {};
    for (final row in rows) {
      final String id = _text(row['accession']);
      final int version = _asInt(row['version']) ?? 0;
      final int known = _asInt(latest[id]?['version']) ?? -1;
      if (version > known) latest[id] = row;
    }
    return latest.values.toList();
  }

  String _title(Map<String, Object?> row, DownloadContent content) {
    final List<String> fields = switch (content) {
      DownloadContent.reads => [
          'library_layout',
          'library_strategy',
          'experiment_title',
        ],
      DownloadContent.assembly => ['assembly_name', 'assembly_level'],
      _ => ['description'],
    };
    return fields
        .map((field) => _text(row[field]))
        .where((value) => value.isNotEmpty)
        .join(' · ');
  }

  String _result(DownloadContent content) {
    return switch (content) {
      DownloadContent.nucleotide => 'sequence',
      DownloadContent.coding => 'coding',
      DownloadContent.reads => 'read_run',
      DownloadContent.assembly => 'assembly',
      DownloadContent.protein =>
        throw const DatabaseException('ENA has no proteins. Use GenBank.'),
    };
  }

  String _fields(DownloadContent content) {
    return switch (content) {
      DownloadContent.coding =>
        'accession,parent_accession,sequence_version,description,'
            'scientific_name,base_count,gene,codon_start',
      DownloadContent.reads =>
        'run_accession,scientific_name,experiment_title,library_layout,'
            'library_strategy,fastq_ftp,fastq_bytes,fastq_md5',
      DownloadContent.assembly =>
        'accession,version,assembly_name,assembly_level,scientific_name,'
            'base_count',
      _ => 'accession,sequence_version,description,scientific_name,base_count',
    };
  }

  Uri _portal(String endpoint) => Uri.https(_host, '/ena/portal/api/$endpoint');

  Uri _taxonomy(String endpoint, String name, [Map<String, String>? query]) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['ena', 'taxonomy', 'rest', endpoint, name],
      queryParameters: query,
    );
  }
}

/// The FASTQ files of a run. ENA separates paired files with semicolons, and
/// lists none for some runs.
List<RemoteFile> parseRunFiles(Map<String, Object?> row) {
  final String addresses = _text(row['fastq_ftp']);
  if (addresses.isEmpty) return const [];
  final List<String> urls = addresses.split(';');
  final List<String> sizes = _text(row['fastq_bytes']).split(';');
  final List<String> sums = _text(row['fastq_md5']).split(';');
  return [
    for (final (int i, String url) in urls.indexed)
      if (url.isNotEmpty)
        RemoteFile(
          url: archiveFileUrl(url),
          bytes: sizes.length == urls.length ? int.tryParse(sizes[i]) : null,
          md5:
              sums.length == urls.length && sums[i].isNotEmpty ? sums[i] : null,
        ),
  ];
}

List<Map<String, Object?>> _objects(Object? json) {
  return json is List
      ? json.whereType<Map<String, Object?>>().toList()
      : const [];
}

String _text(Object? value) => value?.toString().trim() ?? '';

int? _asInt(Object? value) => int.tryParse(_text(value));

//! GenBank through the NCBI E-utilities.

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:segui/services/databases/archive.dart';
import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/types.dart';

class GenBankArchive extends SequenceArchive {
  const GenBankArchive(super.client);

  static const int pageSize = 50;

  /// E-utilities list at most this many summaries of one search.
  static const int _maxResults = 10000;

  /// NCBI asks E-utilities clients for a tool name and a contact email, so
  /// it can reach the developer before blocking heavy use.
  static const Map<String, String> _identity = {
    'tool': 'segui',
    'email': 'herubiolog@gmail.com',
  };

  @override
  DatabaseSource get source => DatabaseSource.genBank;

  @override
  int get batchSize => 100;

  @override
  Future<DatabasePage> search(
    DatabaseQuery query, {
    PageCursor? after,
    CancelToken? cancel,
  }) async {
    if (!query.hasTerms) {
      throw const DatabaseException(
        'Enter an organism, gene, or keyword.',
      );
    }
    final String db = _database(query.content);
    String? webEnv = after?.webEnv;
    String? queryKey = after?.queryKey;
    int total = after?.total ?? 0;
    if (after == null) {
      final result = await _esearch({
        'db': db,
        'term': buildTerm(query),
        'usehistory': 'y',
        'retmax': '0',
      }, cancel);
      total = _asInt(result['count']) ?? 0;
      if (total == 0) return DatabasePage.empty;
      webEnv = result['webenv']?.toString();
      queryKey = result['querykey']?.toString();
    }
    final int offset = after?.offset ?? 0;
    final records = await _esummary({
      'db': db,
      'WebEnv': webEnv ?? '',
      'query_key': queryKey ?? '',
      'retstart': '$offset',
      'retmax': '$pageSize',
    }, query.content, cancel);
    final int end = offset + pageSize;
    final bool hasMore = end < _maxResults && end < total;
    return DatabasePage(
      records: records,
      total: total,
      next: hasMore
          ? PageCursor(
              offset: end,
              total: total,
              webEnv: webEnv,
              queryKey: queryKey,
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
    final String db = _database(content);
    final String field = content == DownloadContent.assembly
        ? 'Assembly Accession'
        : 'Accession';
    final List<DatabaseRecord> found = [];
    for (final List<String> batch in batches(accessions, batchSize)) {
      final result = await _esearch({
        'db': db,
        'term': batch.map((accession) => '$accession[$field]').join(' OR '),
        'retmax': '${max(batch.length * 5, pageSize)}',
      }, cancel);
      final List<Object?> ids = result['idlist'] as List<Object?>? ?? const [];
      if (ids.isEmpty) continue;
      found.addAll(await _esummary(
        {'db': db, 'id': ids.join(',')},
        content,
        cancel,
        requested: batch,
      ));
    }
    final List<DatabaseRecord> records = [];
    final List<String> missing = [];
    for (final String accession in accessions) {
      final match = found
          .where((record) => accessionMatches(accession, record.accession))
          .firstOrNull;
      if (match == null) {
        missing.add(accession);
      } else if (!records.contains(match)) {
        records.add(match);
      }
    }
    return DatabasePage(
      records: records,
      total: records.length,
      missing: missing,
    );
  }

  @override
  Future<List<String>> suggestOrganisms(
    String text, {
    CancelToken? cancel,
  }) async {
    final String term = cleanTerm(text);
    if (term.isEmpty) return const [];
    final result = await _esearch({
      'db': 'taxonomy',
      'term': '$term*[All Names]',
      'retmax': '8',
    }, cancel);
    final List<Object?> ids = result['idlist'] as List<Object?>? ?? const [];
    if (ids.isEmpty) return const [];
    final summaries = await _summaries(
      {'db': 'taxonomy', 'id': ids.join(',')},
      cancel,
    );
    return [
      for (final taxon in summaries)
        if (_text(taxon['scientificname']).isNotEmpty)
          _text(taxon['scientificname']),
    ];
  }

  @override
  Future<RawFasta> saveFasta(
    List<DatabaseRecord> records,
    File destination, {
    CancelToken? cancel,
    void Function(int bytes)? onReceived,
  }) async {
    final DownloadContent content = records.first.content;
    final Uri url = _utility('efetch');
    final Map<String, String> form = {
      'db': _database(content),
      'rettype': content == DownloadContent.coding ? 'fasta_cds_na' : 'fasta',
      'retmode': 'text',
      'id': records.map((record) => record.accession).join(','),
    };
    await client.save(
      url,
      destination,
      form: {...form, ..._identity},
      cancel: cancel,
      onReceived: onReceived,
    );
    return RawFasta(
      file: destination,
      url: url.replace(queryParameters: form),
    );
  }

  @override
  FastaOrigin readHeader(String header) {
    String id = header.split(RegExp(r'\s')).first;
    if (id.startsWith('lcl|')) {
      id = id.substring(4);
      final int cds = id.indexOf('_cds');
      if (cds > 0) id = id.substring(0, cds);
    } else if (id.contains('|')) {
      final List<String> parts = id.split('|');
      // Such as sp|P12345.2|NAME, pdb|1ABC|A, and pir||A12345.
      id = parts.first == 'pdb' && parts.length > 2
          ? '${parts[1]}_${parts[2]}'
          : parts.skip(1).firstWhere(
                (part) => part.isNotEmpty,
                orElse: () => id,
              );
    }
    return FastaOrigin(
      accession: id,
      gene: _tag(header, 'gene'),
      product: _tag(header, 'protein'),
      codonStart: int.tryParse(_tag(header, 'frame')),
    );
  }

  /// The E-utilities search term of [query].
  static String buildTerm(DatabaseQuery query) {
    final bool isAssembly = query.content == DownloadContent.assembly;
    final String organism = cleanTerm(query.organism);
    final String gene = cleanTerm(query.gene);
    final String keyword = cleanTerm(query.keyword);
    final int? low = query.minLength;
    final int? high = query.maxLength;
    return [
      if (organism.isNotEmpty) '"$organism"[Organism]',
      if (gene.isNotEmpty && !isAssembly) '"$gene"[Gene]',
      if (keyword.isNotEmpty)
        isAssembly ? '"$keyword"[All Fields]' : '"$keyword"[Title]',
      if (query.content == DownloadContent.coding) 'cds[Feature key]',
      if (!isAssembly && (low != null || high != null))
        '${low ?? 1}:${high ?? 999999999}[SLEN]',
      if (isAssembly)
        query.refSeqOnly ? 'latest_refseq[filter]' : 'latest[filter]'
      else if (query.refSeqOnly)
        query.content == DownloadContent.protein
            ? 'refseq[filter]'
            : 'srcdb_refseq[PROP]',
    ].join(' AND ');
  }

  Future<Map<String, Object?>> _esearch(
    Map<String, String> form,
    CancelToken? cancel,
  ) async {
    final json = await _json('esearch', form, cancel);
    final Object? result = json['esearchresult'];
    if (result is! Map<String, Object?> || result['ERROR'] != null) {
      throw const DatabaseException(
        'GenBank could not run the search. Try again.',
      );
    }
    return result;
  }

  Future<List<DatabaseRecord>> _esummary(
    Map<String, String> form,
    DownloadContent content,
    CancelToken? cancel, {
    List<String> requested = const [],
  }) async {
    final summaries = await _summaries(form, cancel);
    return [
      for (final summary in summaries)
        if (content == DownloadContent.assembly)
          ..._assemblies(summary, requested)
        else if (_text(summary['accessionversion']).isNotEmpty)
          DatabaseRecord(
            source: source,
            content: content,
            accession: _text(summary['accessionversion']),
            organism: _text(summary['organism']),
            title: _text(summary['title']),
            length: _asInt(summary['slen']),
          ),
    ];
  }

  Future<List<Map<String, Object?>>> _summaries(
    Map<String, String> form,
    CancelToken? cancel,
  ) async {
    final json = await _json('esummary', form, cancel);
    final Object? result = json['result'];
    if (result is! Map<String, Object?>) {
      // Past searches expire on the NCBI history server.
      throw const DatabaseException(
        'GenBank did not return the records. Search again.',
      );
    }
    final List<Object?> uids = result['uids'] as List<Object?>? ?? const [];
    return [
      for (final uid in uids)
        if (result['$uid'] case final Map<String, Object?> summary) summary,
    ];
  }

  /// The GenBank and RefSeq copies of an assembly that were asked for, or
  /// the one NCBI lists when none were.
  List<DatabaseRecord> _assemblies(
    Map<String, Object?> summary,
    List<String> requested,
  ) {
    final String listed = _text(summary['assemblyaccession']);
    final Object? synonym = summary['synonym'];
    final Set<String> copies = {
      listed,
      if (synonym is Map<String, Object?>) ...[
        _text(synonym['genbank']),
        _text(synonym['refseq']),
      ],
    }..remove('');
    final Iterable<String> wanted = requested.isEmpty
        ? [listed]
        : copies.where(
            (copy) => requested.any((e) => accessionMatches(e, copy)),
          );
    return [
      for (final String accession in wanted)
        DatabaseRecord(
          source: source,
          content: DownloadContent.assembly,
          accession: accession,
          organism: _text(summary['speciesname']),
          title: [
            _text(summary['assemblyname']),
            _text(summary['assemblystatus']),
          ].where((part) => part.isNotEmpty).join(' · '),
          length: _totalLength(_text(summary['meta'])),
          files: _assemblyFiles(summary, accession),
        ),
    ];
  }

  List<RemoteFile> _assemblyFiles(
    Map<String, Object?> summary,
    String accession,
  ) {
    final String folder = _text(summary[
        accession.startsWith('GCF_') ? 'ftppath_refseq' : 'ftppath_genbank']);
    if (folder.isEmpty || !folder.contains(accession)) return const [];
    final Uri url = archiveFileUrl(folder);
    final String name = '${p.url.basename(url.path)}_genomic.fna.gz';
    return [RemoteFile(url: url.replace(path: p.url.join(url.path, name)))];
  }

  int? _totalLength(String meta) {
    final match = RegExp(
      r'category="total_length" sequence_tag="all">(\d+)<',
    ).firstMatch(meta);
    return match == null ? null : int.parse(match.group(1)!);
  }

  Future<Map<String, Object?>> _json(
    String utility,
    Map<String, String> form,
    CancelToken? cancel,
  ) async {
    final response = await client.read(
      _utility(utility),
      form: {...form, 'retmode': 'json', ..._identity},
      cancel: cancel,
    );
    if (!response.isOk) {
      throw DatabaseException(
        'GenBank is unavailable (${response.status}). Try again later.',
      );
    }
    final Object? json = decodeArchiveJson(response.body);
    if (json is! Map<String, Object?>) {
      throw const DatabaseException('GenBank sent an unexpected answer.');
    }
    return json;
  }

  String _database(DownloadContent content) {
    return switch (content) {
      DownloadContent.nucleotide || DownloadContent.coding => 'nuccore',
      DownloadContent.protein => 'protein',
      DownloadContent.assembly => 'assembly',
      DownloadContent.reads =>
        throw const DatabaseException('GenBank has no FASTQ files. Use ENA.'),
    };
  }

  String _tag(String header, String name) {
    return RegExp('\\[$name=([^\\]]*)\\]').firstMatch(header)?.group(1) ?? '';
  }

  Uri _utility(String name) =>
      Uri.https('eutils.ncbi.nlm.nih.gov', '/entrez/eutils/$name.fcgi');
}

String _text(Object? value) => value?.toString().trim() ?? '';

int? _asInt(Object? value) => int.tryParse(_text(value));

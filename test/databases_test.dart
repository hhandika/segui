import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/databases/assembly.dart';
import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/compatibility.dart';
import 'package:segui/services/databases/download.dart';
import 'package:segui/services/databases/ena.dart';
import 'package:segui/services/databases/fasta.dart';
import 'package:segui/services/databases/genbank.dart';
import 'package:segui/services/databases/types.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';

import 'databases_fake.dart';

// Shortened from responses of 2026-11-22.
const String partialCds = '>lcl|U49845.1_cds_AAA98665.1_1 '
    '[protein=TCP1-beta] [frame=3] [location=<1..206] [gbkey=CDS]\n'
    'TCCTCCATATAC\n'
    '>lcl|U49845.1_cds_AAA98666.1_2 '
    '[gene=AXL2] [protein=Axl2p] [location=687..3158] [gbkey=CDS]\n'
    'ATGACACAGCTT\n';

const String efetchError =
    'Error: F a i l e d  t o  u n d e r s t a n d  i d :  Z Z 9 9 9 9 9 9 \n\n';

DatabaseRecord record(
  String accession, {
  DatabaseSource source = DatabaseSource.genBank,
  DownloadContent content = DownloadContent.nucleotide,
  String organism = 'Mus musculus',
  int? length,
  int codonStart = 1,
  String gene = '',
  List<RemoteFile> files = const [],
}) {
  return DatabaseRecord(
    source: source,
    content: content,
    accession: accession,
    organism: organism,
    length: length,
    codonStart: codonStart,
    gene: gene,
    files: files,
  );
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('segui-databases-');
  });

  tearDown(() => root.delete(recursive: true));

  DownloadJob jobFor(
    FakeDatabaseClient client,
    List<DatabaseRecord> records, {
    DownloadOptions options = const DownloadOptions(),
    bool trimsToFrame = false,
    Set<String> takenNames = const {},
  }) {
    return DownloadJob(
      client: client,
      archives: {
        DatabaseSource.genBank: GenBankArchive(client),
        DatabaseSource.ena: EnaArchive(client),
      },
      records: records,
      options: options,
      trimsToFrame: trimsToFrame,
      root: root,
      takenNames: takenNames,
      now: () => DateTime(2026, 11, 22, 12),
    );
  }

  group('Compatibility', () {
    const sequenceContents = [
      DownloadContent.nucleotide,
      DownloadContent.coding,
      DownloadContent.protein,
    ];
    // Every task is listed, so a new task fails until its rule is chosen.
    const Map<SupportedTask, Object?> expected = {
      SupportedTask.sequenceAddition: sequenceContents,
      SupportedTask.sequenceExtraction: sequenceContents,
      SupportedTask.sequenceFiltering: sequenceContents,
      SupportedTask.sequenceRemoval: sequenceContents,
      SupportedTask.sequenceRenaming: sequenceContents,
      SupportedTask.sequenceTransposition: sequenceContents,
      SupportedTask.sequenceUniqueId: sequenceContents,
      SupportedTask.alignmentConversion: sequenceContents,
      SupportedTask.sequenceTranslation: [DownloadContent.coding],
      SupportedTask.genomicRawReadSummary: [DownloadContent.reads],
      SupportedTask.genomicContigSummary: [DownloadContent.assembly],
      SupportedTask.alignmentConcatenation: 'aligned',
      SupportedTask.alignmentDistance: 'aligned',
      SupportedTask.alignmentFiltering: 'aligned',
      SupportedTask.alignmentSplitting: 'aligned',
      SupportedTask.alignmentSummary: 'aligned',
      SupportedTask.alignmentTrimming: 'aligned',
      SupportedTask.alignmentUnalignment: 'aligned',
      SupportedTask.partitionConversion: null,
      SupportedTask.genomicMafConversion: null,
      SupportedTask.genomicMafSummary: null,
    };

    XTypeGroup mainGroup(SupportedTask task) => switch (task) {
          SupportedTask.genomicRawReadSummary => genomicRawReadTypeGroup,
          SupportedTask.genomicContigSummary => genomicContigTypeGroup,
          SupportedTask.genomicMafConversion ||
          SupportedTask.genomicMafSummary =>
            mafTypeGroup,
          SupportedTask.partitionConversion => partitionTypeGroup,
          _ => sequenceTypeGroup,
        };

    for (final task in SupportedTask.values) {
      test('$task', () {
        expect(expected.containsKey(task), isTrue);
        final support = databaseSupportFor(task, mainGroup(task));
        switch (expected[task]) {
          case final List<DownloadContent> contents:
            expect((support as DatabaseAvailable).contents, contents);
          case 'aligned':
            expect(support, same(needsAlignment));
          default:
            expect(support, isA<DatabaseNotOffered>());
        }
      });
    }

    test('Secondary pickers get nothing', () {
      for (final task in SupportedTask.values) {
        for (final group in [
          plainTextTypeGroup,
          bedTypeGroup,
          sampleGroupTypeGroup,
        ]) {
          expect(databaseSupportFor(task, group), isA<DatabaseNotOffered>());
        }
      }
      expect(
        databaseSupportFor(
            SupportedTask.alignmentSplitting, partitionTypeGroup),
        isA<DatabaseNotOffered>(),
      );
    });

    test('Add sequences offers both of its pickers', () {
      expect(
        databaseSupportFor(
            SupportedTask.sequenceAddition, destinationSequenceTypeGroup),
        isA<DatabaseAvailable>(),
      );
    });

    test('Sources follow the content', () {
      DatabaseAvailable of(SupportedTask task) =>
          databaseSupportFor(task, mainGroup(task)) as DatabaseAvailable;
      expect(of(SupportedTask.genomicRawReadSummary).sources,
          [DatabaseSource.ena]);
      expect(
        of(SupportedTask.sequenceFiltering).contentsOf(DatabaseSource.ena),
        [DownloadContent.nucleotide, DownloadContent.coding],
      );
      expect(of(SupportedTask.sequenceTranslation).trimsToFrame, isTrue);
      expect(of(SupportedTask.sequenceFiltering).trimsToFrame, isFalse);
    });

    test('Downloaded names match the picker of their tool', () {
      expect(matchesTypeGroup(File('a.fasta'), sequenceTypeGroup), isTrue);
      expect(matchesTypeGroup(File('a.fna'), genomicContigTypeGroup), isTrue);
      expect(
        matchesTypeGroup(File('a_1.fastq.gz'), genomicRawReadTypeGroup),
        isTrue,
      );
    });
  });

  group('Accessions', () {
    test('Paste accepts commas, spaces, and lines', () {
      final parsed =
          parseAccessions('u49845.1, NC_005089\nGCA_000146045.2;U49845.1 nope');
      expect(
        parsed.accessions,
        ['U49845.1', 'NC_005089', 'GCA_000146045.2'],
      );
      expect(parsed.invalid, ['nope']);
    });

    test('A version must match when given', () {
      expect(accessionMatches('U49845', 'U49845.1'), isTrue);
      expect(accessionMatches('U49845.1', 'U49845.1'), isTrue);
      expect(accessionMatches('U49845.2', 'U49845.1'), isFalse);
    });

    test('Names are safe for SEGUL', () {
      expect(safeName('Mus musculus_NC_005089.1'), 'Mus_musculus_NC_005089.1');
      expect(safeName("Rattus sp. 'NH-2147'"), 'Rattus_sp._NH_2147');
      expect(safeName('../../etc/passwd'), 'etc_passwd');
      expect(safeName('///'), 'sequence');
    });

    test('Only HTTPS addresses of the archives are used', () {
      expect(isArchiveUrl(Uri.parse('https://www.ebi.ac.uk/ena')), isTrue);
      expect(isArchiveUrl(Uri.parse('http://www.ebi.ac.uk/ena')), isFalse);
      expect(isArchiveUrl(Uri.parse('https://ebi.ac.uk.evil.test/')), isFalse);
      expect(isArchiveUrl(Uri.parse('https://evilncbi.nlm.nih.gov/')), isFalse);
    });

    test('FTP and scheme-less addresses become HTTPS', () {
      expect('${archiveFileUrl('ftp.sra.ebi.ac.uk/vol1/a.gz')}',
          'https://ftp.sra.ebi.ac.uk/vol1/a.gz');
      expect('${archiveFileUrl('ftp://ftp.ncbi.nlm.nih.gov/genomes')}',
          'https://ftp.ncbi.nlm.nih.gov/genomes');
    });
  });

  group('GenBank', () {
    test('Builds the search term', () {
      expect(
        GenBankArchive.buildTerm(const DatabaseQuery(
          content: DownloadContent.coding,
          organism: 'Rattus',
          gene: 'CYTB"] OR all[filter',
          minLength: 1000,
          refSeqOnly: true,
        )),
        '"Rattus"[Organism] AND "CYTB OR all filter"[Gene] AND '
        'cds[Feature key] AND 1000:999999999[SLEN] AND srcdb_refseq[PROP]',
      );
      expect(
        GenBankArchive.buildTerm(const DatabaseQuery(
          content: DownloadContent.assembly,
          organism: 'Mus',
          refSeqOnly: true,
        )),
        '"Mus"[Organism] AND latest_refseq[filter]',
      );
    });

    test('Pages through the history server and keeps the total', () async {
      final client = FakeDatabaseClient((url, form) {
        if (url.path.endsWith('esearch.fcgi')) {
          return ok(jsonEncode({
            'esearchresult': {'count': '120', 'webenv': 'W', 'querykey': '1'},
          }));
        }
        return ok(jsonEncode({
          'result': {
            'uids': ['1'],
            '1': {
              'accessionversion': 'U${form['retstart']}.1',
              'organism': 'Mus',
              'slen': 5028,
            },
          },
        }));
      });
      final archive = GenBankArchive(client);
      const query = DatabaseQuery(
        content: DownloadContent.nucleotide,
        organism: 'Mus',
      );
      final first = await archive.search(query);
      final second = await archive.search(query, after: first.next);
      final third = await archive.search(query, after: second.next);
      expect([first.total, second.total, third.total], [120, 120, 120]);
      expect(second.records.single.accession, 'U50.1');
      expect(third.next, isNull);
    });

    test('Lookup reports the accessions it did not find', () async {
      final client = FakeDatabaseClient((url, form) {
        if (url.path.endsWith('esearch.fcgi')) {
          return ok('{"esearchresult":{"idlist":["1293613"]}}');
        }
        return ok('{"error":"Invalid uid at position= 8","result":{'
            '"uids":["1293613"],"1293613":{"slen":5028,'
            '"accessionversion":"U49845.1"}}}');
      });
      final page = await GenBankArchive(client).lookUp(
        ['U49845.1', 'ZZ999999', 'U49845.7'],
        DownloadContent.nucleotide,
      );
      expect(page.records.single.accession, 'U49845.1');
      expect(page.missing, ['ZZ999999', 'U49845.7']);
    });

    test('Gives the RefSeq or GenBank copy that was asked for', () async {
      const base = 'ftp://ftp.ncbi.nlm.nih.gov/genomes/all';
      final client = FakeDatabaseClient((url, form) {
        if (url.path.endsWith('esearch.fcgi')) {
          return ok('{"esearchresult":{"idlist":["285498"]}}');
        }
        return ok(jsonEncode({
          'result': {
            'uids': ['285498'],
            '285498': {
              'assemblyaccession': 'GCF_000146045.2',
              'synonym': {
                'genbank': 'GCA_000146045.2',
                'refseq': 'GCF_000146045.2',
              },
              'ftppath_genbank': '$base/GCA_000146045.2_R64',
              'ftppath_refseq': '$base/GCF_000146045.2_R64',
              'meta': '<Stat category="total_length" sequence_tag="all">'
                  '12157105</Stat>',
            },
          },
        }));
      });
      final page = await GenBankArchive(client)
          .lookUp(['GCA_000146045.2'], DownloadContent.assembly);
      final found = page.records.single;
      expect(found.accession, 'GCA_000146045.2');
      expect(found.length, 12157105);
      expect(
        '${found.files.single.url}',
        'https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA_000146045.2_R64/'
            'GCA_000146045.2_R64_genomic.fna.gz',
      );
    });

    test('Reads the accession from each kind of header', () {
      final archive = GenBankArchive(FakeDatabaseClient((_, __) => ok('')));
      String id(String header) => archive.readHeader(header).accession;
      expect(id('U49845.1 Saccharomyces'), 'U49845.1');
      expect(id('sp|P12345.2|AATM_RABIT Aspartate'), 'P12345.2');
      expect(id('pdb|1ABC|A Chain A'), '1ABC_A');
      final cds = archive.readHeader(
          'lcl|NC_005089.1_cds_NP_904340.1_13 [gene=CYTB] [frame=2]');
      expect(cds.accession, 'NC_005089.1');
      expect(cds.gene, 'CYTB');
      expect(cds.codonStart, 2);
    });
  });

  group('ENA', () {
    test('Text searches have no wildcards', () {
      final query = EnaArchive.buildQuery(
        const DatabaseQuery(
          content: DownloadContent.nucleotide,
          keyword: 'cytochrome b',
          maxLength: 20000,
        ),
        10117,
      );
      expect(
        query,
        'tax_tree(10117) AND description="cytochrome b" AND base_count<=20000',
      );
    });

    test('Raises the limit instead of sending an offset', () async {
      final client = FakeDatabaseClient((url, form) {
        if (url.path.contains('any-name')) return ok('[{"taxId":"10114"}]');
        if (url.path.endsWith('count')) return ok('{"count":"4000"}');
        expect(form, isNot(contains('offset')));
        return ok(jsonEncode([
          for (int i = 0; i < int.parse(form['limit']!); i++)
            {'accession': 'AB${100000 + i}', 'sequence_version': '1'},
        ]));
      });
      final archive = EnaArchive(client);
      const query = DatabaseQuery(
        content: DownloadContent.nucleotide,
        organism: 'Rattus',
      );
      DatabasePage page = await archive.search(query);
      expect(page.records, hasLength(100));
      expect(page.total, 4000);
      while (page.next != null) {
        page = await archive.search(query, after: page.next);
      }
      expect(page.records, hasLength(EnaArchive.maxResults));
    });

    test('Needs an organism', () {
      final archive = EnaArchive(FakeDatabaseClient((_, __) => ok('[]')));
      expect(
        () => archive.search(const DatabaseQuery(
          content: DownloadContent.nucleotide,
          keyword: 'cytb',
        )),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('Keeps the latest version of each assembly', () async {
      final client = FakeDatabaseClient((url, form) {
        return ok('[{"accession":"GCA_000146045","version":"1"},'
            '{"accession":"GCA_000146045","version":"2"}]');
      });
      final archive = EnaArchive(client);
      final page =
          await archive.lookUp(['GCA_000146045'], DownloadContent.assembly);
      expect(page.records.single.accession, 'GCA_000146045.2');
      final old =
          await archive.lookUp(['GCA_000146045.1'], DownloadContent.assembly);
      expect(old.records, isEmpty);
      expect(old.missing, ['GCA_000146045.1']);
    });

    test('One rejected accession does not hide the others', () async {
      final client = FakeDatabaseClient((url, form) {
        final ids = form['includeAccessions']!.split(',');
        if (ids.contains('AB999999')) return (status: 400, body: '{}');
        return ok(jsonEncode([
          for (final id in ids) {'accession': id, 'sequence_version': '1'},
        ]));
      });
      final page = await EnaArchive(client).lookUp(
        ['U49845', 'AB999999', 'NC_005089', 'AY172335'],
        DownloadContent.nucleotide,
      );
      expect(page.records.map((e) => e.accession), ['U49845.1', 'AY172335.1']);
      expect(page.missing, ['AB999999', 'NC_005089']);
    });

    test('Coding records take the organism of their parent', () async {
      final client = FakeDatabaseClient((url, form) {
        if (form['result'] == 'coding') {
          return ok('[{"accession":"AAA98665","parent_accession":"U49845",'
              '"sequence_version":"1","scientific_name":"","codon_start":"3"}]');
        }
        return ok('[{"accession":"U49845",'
            '"scientific_name":"Saccharomyces cerevisiae"}]');
      });
      final page =
          await EnaArchive(client).lookUp(['U49845.1'], DownloadContent.coding);
      expect(page.records.single.organism, 'Saccharomyces cerevisiae');
      expect(page.records.single.codonStart, 3);
      expect(page.missing, isEmpty);
    });

    test('Reads paired, single, and absent run files', () {
      final pair = parseRunFiles({
        'fastq_ftp': 'ftp.sra.ebi.ac.uk/R_1.fastq.gz;'
            'ftp.sra.ebi.ac.uk/R_2.fastq.gz',
        'fastq_bytes': '26930;33990',
        'fastq_md5': 'aa;bb',
      });
      expect(pair.map((e) => e.bytes), [26930, 33990]);
      expect(pair.map((e) => e.md5), ['aa', 'bb']);
      expect(pair.first.url.scheme, 'https');
      expect(parseRunFiles({'fastq_ftp': 'ftp.sra.ebi.ac.uk/R.fastq.gz'}),
          hasLength(1));
      expect(parseRunFiles({'fastq_ftp': ''}), isEmpty);
    });
  });

  group('Sequence downloads', () {
    test('An error sent with a success status fails', () async {
      final job = jobFor(
        FakeDatabaseClient((_, __) => ok(efetchError)),
        [record('ZZ999999')],
      );
      final report = await job.run();
      expect(report.completed, 0);
      expect(report.failures.single.reason, contains('error instead'));
      await job.discard();
      expect(root.listSync(), isEmpty);
    });

    test('Reports records dropped from a batch', () async {
      final job = jobFor(
        FakeDatabaseClient((_, __) => ok('>U49845.1 Yeast\nACGT\n')),
        [record('U49845.1'), record('AB000002.1')],
      );
      final report = await job.run();
      expect(report.completed, 1);
      expect(report.failures.single.record.accession, 'AB000002.1');
    });

    test('Another version is not accepted', () async {
      final job = jobFor(
        FakeDatabaseClient((_, __) => ok('>U49845.2 Yeast\nACGT\n')),
        [record('U49845.1')],
      );
      expect((await job.run()).completed, 0);
    });

    test('Rewrites headers and numbers repeated IDs', () async {
      final job = jobFor(
        FakeDatabaseClient((_, __) => ok('>U49845.1 first copy, with spaces\n'
            'ACGT\n>U49845.1 second copy\nGGCC\n')),
        [record('U49845.1')],
      );
      await job.run();
      final completed = await job.commit();
      expect(completed.dataType, 'DNA');
      expect(completed.files.single.readAsLinesSync(), [
        '>Mus_musculus_U49845.1',
        'ACGT',
        '>Mus_musculus_U49845.1_2',
        'GGCC',
      ]);
    });

    test('Trims partial coding sequences for translation', () async {
      final job = jobFor(
        FakeDatabaseClient((_, __) => ok(partialCds)),
        [record('U49845.1', content: DownloadContent.coding)],
        trimsToFrame: true,
      );
      await job.run();
      final file = (await job.commit()).files.single;
      expect(file.readAsLinesSync(), [
        '>Mus_musculus_U49845.1_TCP1_beta',
        'CTCCATATAC',
        '>Mus_musculus_U49845.1_AXL2',
        'ATGACACAGCTT',
      ]);
    });

    test('Keeps every base for other tools', () async {
      final job = jobFor(
        FakeDatabaseClient((_, __) => ok(partialCds)),
        [record('U49845.1', content: DownloadContent.coding)],
      );
      await job.run();
      expect((await job.commit()).files.single.readAsLinesSync(),
          contains('TCCTCCATATAC'));
    });

    test('Trims ENA coding sequences by their codon start', () async {
      final job = jobFor(
        FakeDatabaseClient(
            (_, __) => ok('>ENA|AAA98665|AAA98665.1 Yeast\nT\nCCTCC\n')),
        [
          record(
            'AAA98665.1',
            source: DatabaseSource.ena,
            content: DownloadContent.coding,
            codonStart: 3,
          ),
        ],
        trimsToFrame: true,
      );
      await job.run();
      expect((await job.commit()).files.single.readAsLinesSync().last, 'CTCC');
    });

    test('Keeps only the chosen gene', () async {
      final job = jobFor(
        FakeDatabaseClient((_, __) => ok(partialCds)),
        [record('U49845.1', content: DownloadContent.coding)],
        options: const DownloadOptions(gene: 'axl-2'),
      );
      await job.run();
      final file = (await job.commit()).files.single;
      expect(
          file.readAsLinesSync(), ['>Mus_musculus_U49845.1', 'ATGACACAGCTT']);
      expect(p.basename(file.path), 'axl_2.fasta');
    });

    test('Writes a file per record without dots in the name', () async {
      final job = jobFor(
        FakeDatabaseClient(
            (_, __) => ok('>AB000001.1 a\nACGT\n>AB000002.1 b\nGGCC\n')),
        [record('AB000001.1'), record('AB000002.1')],
        options: const DownloadOptions(
          grouping: SequenceGrouping.perRecord,
          naming: SequenceNaming.accession,
        ),
      );
      await job.run();
      final files = (await job.commit()).files;
      expect(files.map((e) => p.basename(e.path)),
          ['AB000001_1.fasta', 'AB000002_1.fasta']);
      expect(files.last.readAsLinesSync(), ['>AB000002.1', 'GGCC']);
    });

    test('Does not repeat a name the picker holds', () async {
      final job = jobFor(
        FakeDatabaseClient((_, __) => ok('>U49845.1 a\nACGT\n')),
        [record('U49845.1')],
        options: const DownloadOptions(fileName: 'cytb'),
        takenNames: {'CYTB'},
      );
      await job.run();
      expect(
          p.basename((await job.commit()).files.single.path), 'cytb_2.fasta');
    });

    test('Sets the data type from the content and residues', () async {
      Future<String?> typeOf(DownloadContent content, String residues) async {
        final job = jobFor(
          FakeDatabaseClient((_, __) => ok('>AB000001.1 a\n$residues\n')),
          [record('AB000001.1', content: content)],
        );
        await job.run();
        return (await job.commit()).dataType;
      }

      expect(await typeOf(DownloadContent.nucleotide, 'ACGTN'), 'DNA');
      expect(await typeOf(DownloadContent.protein, 'MTNMRK'), 'AA');
      // SEGUL rejects pyrrolysine as an amino acid.
      expect(await typeOf(DownloadContent.protein, 'MTOK'), 'Ignore');
    });

    test('Retry adds only what failed, to the same file', () async {
      bool isRetry = false;
      final client = FakeDatabaseClient((_, form) {
        return ok(isRetry ? '>AB000002.1 b\nGGCC\n' : '>AB000001.1 a\nACGT\n');
      });
      final job = jobFor(client, [record('AB000001.1'), record('AB000002.1')]);
      expect((await job.run()).completed, 1);
      isRetry = true;
      expect((await job.run()).isComplete, isTrue);
      expect(client.requests.last.form['id'], 'AB000002.1');
      expect((await job.commit()).files.single.readAsLinesSync(), hasLength(4));
    });

    test('Lists the source of each sequence', () async {
      final job = jobFor(
        FakeDatabaseClient((_, __) => ok('>U49845.1 Yeast genes\nACGT\n')),
        [record('U49845.1')],
      );
      await job.run();
      final completed = await job.commit();
      final sources = File(
        p.join(completed.files.single.parent.path, sourcesFileName),
      ).readAsLinesSync();
      expect(sources, hasLength(2));
      expect(sources.last, contains('U49845.1 Yeast genes'));
      expect(sources.last, startsWith('GenBank\tU49845.1\t'));
    });

    test('Cancel deletes the download', () async {
      final token = CancelToken();
      final client = FakeDatabaseClient((_, __) => ok('>U49845.1 a\nACGT\n'))
        ..onSaved = token.cancel;
      final job = jobFor(client, [record('U49845.1')]);
      await expectLater(
        job.run(cancel: token),
        throwsA(isA<DatabaseCancelled>()),
      );
      expect(root.listSync(), isEmpty);
    });
  });

  group('Run downloads', () {
    final List<int> first = gzip.encode(utf8.encode('@r\nAC\n+\nII\n'));
    final List<int> second = gzip.encode(utf8.encode('@r\nGT\n+\nII\n'));

    RemoteFile remote(String name, List<int> bytes, {String? sum, int? size}) {
      return RemoteFile(
        url: Uri.parse('https://ftp.sra.ebi.ac.uk/$name'),
        bytes: size ?? bytes.length,
        md5: sum ?? md5.convert(bytes).toString(),
      );
    }

    FakeDatabaseClient runs() => FakeDatabaseClient(
        (url, _) => ok(url.path.contains('_1') ? first : second));

    DatabaseRecord run(List<RemoteFile> files) => record(
          'SRR1',
          source: DatabaseSource.ena,
          content: DownloadContent.reads,
          files: files,
        );

    test('Saves both files of a pair', () async {
      final job = jobFor(runs(), [
        run([
          remote('SRR1_1.fastq.gz', first),
          remote('SRR1_2.fastq.gz', second),
        ]),
      ]);
      expect((await job.run()).isComplete, isTrue);
      final completed = await job.commit();
      expect(completed.files.map((e) => p.basename(e.path)),
          ['SRR1_1.fastq.gz', 'SRR1_2.fastq.gz']);
      expect(completed.dataType, isNull);
    });

    test('A bad checksum keeps neither file', () async {
      final job = jobFor(runs(), [
        run([
          remote('SRR1_1.fastq.gz', first),
          remote('SRR1_2.fastq.gz', second, sum: 'bad'),
        ]),
      ]);
      final report = await job.run();
      expect(report.completed, 0);
      expect(report.failures.single.reason, contains('checksum'));
      await expectLater(job.commit(), throwsA(isA<DatabaseException>()));
    });

    test('A short file fails', () async {
      final job = jobFor(runs(), [
        run([remote('SRR1_1.fastq.gz', first, size: first.length + 1)]),
      ]);
      expect((await job.run()).failures.single.reason, contains('size'));
    });

    test('A run without FASTQ fails', () async {
      final job = jobFor(runs(), [run(const [])]);
      expect((await job.run()).failures.single.reason, contains('no FASTQ'));
    });
  });

  group('Assembly downloads', () {
    // A chromosome, the contig it is built from, and an unplaced contig.
    const fasta = '>ENA|CM000001|CM000001.1 chromosome\nACGTACGT\n'
        '>ENA|JACO02000001|JACO02000001.1 contig\nACGTACGT\n'
        '>ENA|JACO02000002|JACO02000002.1 unplaced\nGGCC\n';
    const report = 'accession\tsequence-name\n'
        'CM000001.1\tI\n'
        'JACO02000002.1\tunplaced\n';

    DownloadJob enaJob({
      required int length,
      FakeReply reportReply = (status: 200, body: report),
    }) {
      return jobFor(
        FakeDatabaseClient(
            (url, _) => url.host.startsWith('ftp') ? reportReply : ok(fasta)),
        [
          record(
            'GCA_000733235.3',
            source: DatabaseSource.ena,
            content: DownloadContent.assembly,
            length: length,
          ),
        ],
      );
    }

    test('Drops the contigs that chromosomes are built from', () async {
      final job = enaJob(length: 12);
      expect((await job.run()).isComplete, isTrue);
      final file = (await job.commit()).files.single;
      expect(p.basename(file.path), 'GCA_000733235_3.fna');
      expect(file.readAsStringSync(), isNot(contains('JACO02000001')));
      expect(file.readAsStringSync(), contains('JACO02000002'));
    });

    test('Keeps everything when there is no report', () async {
      final job = enaJob(length: 20, reportReply: (status: 404, body: ''));
      expect((await job.run()).isComplete, isTrue);
    });

    test('A total that differs fails', () async {
      final doubled = enaJob(length: 12, reportReply: (status: 404, body: ''));
      expect((await doubled.run()).completed, 0);
    });

    test('A sequence missing from the report fails', () async {
      final job = enaJob(
        length: 12,
        reportReply: ok('${report}KN000009.1\tgone\n'),
      );
      expect((await job.run()).completed, 0);
    });

    test('Decompresses and checks GenBank assemblies', () async {
      final bytes = gzip.encode(utf8.encode('>L43967.2 genome\nACGT\n'));
      String sum = md5.convert(bytes).toString();
      final client = FakeDatabaseClient((url, _) {
        return url.path.endsWith('md5checksums.txt')
            ? ok('$sum  ./A_genomic.fna.gz\n')
            : ok(bytes);
      });
      final files = [
        RemoteFile(
          url: Uri.parse('https://ftp.ncbi.nlm.nih.gov/a/A_genomic.fna.gz'),
        ),
      ];
      final good = jobFor(client, [
        record('GCA_000027325.1',
            content: DownloadContent.assembly, files: files),
      ]);
      expect((await good.run()).isComplete, isTrue);
      expect((await good.commit()).files.single.readAsStringSync(),
          '>L43967.2 genome\nACGT\n');

      sum = 'bad';
      final bad = jobFor(client, [
        record('GCA_000027325.1',
            content: DownloadContent.assembly, files: files),
      ]);
      expect((await bad.run()).completed, 0);
    });

    test('An unreadable report fails', () {
      expect(() => parseSequenceReport('<html>'),
          throwsA(isA<DatabaseException>()));
    });
  });
}

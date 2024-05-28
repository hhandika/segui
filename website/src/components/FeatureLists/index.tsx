import clsx from "clsx";
import Heading from "@theme/Heading";

const AlignmentFeatureLists: string[] = [
  "Concatenation",
  "Conversion",
  "Filtering",
  "Partition conversion",
  "Splitting",
  "Summarization",
];

const GenomicFeatureLists: string[] = [
  "Raw read summarization",
  "Contiguous sequence summarization",
];

const SequenceFeatureLists: string[] = [
  "Extraction",
  "Unique ID extraction",
  "ID mapping",
  "ID renaming",
  "Removal",
  "Translation",
];

const FeatureHeader: string[] = ["Alignment", "Genomic", "Sequence"];

// List all feature in tables with "Features" as heading
// and the features in the list
function SupportedFeatures(
  { heading }: { heading: string },
  features: string[]
): JSX.Element {
  return (
    <div>
      <Heading as="h2">{heading}</Heading>
      <table>
        <tbody>
          {features.map((feature) => (
            <tr key={feature}>
              <td>{feature}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export default function SupportedFeatureList(): JSX.Element {
  return (
    <section>
      {SupportedFeatures({ heading: "Alignment" }, AlignmentFeatureLists)}
      {SupportedFeatures({ heading: "Genomic" }, GenomicFeatureLists)}
      {SupportedFeatures({ heading: "Sequence" }, SequenceFeatureLists)}
    </section>
  );
}

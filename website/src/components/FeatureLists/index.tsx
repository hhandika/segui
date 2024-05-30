import clsx from "clsx";
import Heading from "@theme/Heading";

type SupportedItem = {
  title: string;
  description: string;
};

const SupportedList: SupportedItem[] = [
  {
    title: "Alignments",
    description:
      "Concatenate, convert, filter, split, and summarize alignment datasets. \
      Also convert between different partition formats. \
      Support Sanger and next-generation sequencing data.",
  },
  {
    title: "Genomics",
    description:
      "Summarize FASTQ read and contiguous sequence datasets. \
      Work on multiple large datasets simultaneously.",
  },
  {
    title: "Sequences",
    description:
      "Extract, map, rename, remove, and translate sequence datasets. \
      Support Sanger and next-generation sequencing data.",
  },
];

// List all feature in tables with "Features" as heading
// and the features in the list
function SupportedFeatures({ title, description }: SupportedItem): JSX.Element {
  return (
    <div className={clsx("col")}>
      <div className="card">
        <div className="card__header text--primary">
          <Heading as="h3">{title}</Heading>
        </div>
        <div className="card__body">
          <p>{description}</p>
        </div>
      </div>
    </div>
  );
}

export default function SupportedFeatureLists(): JSX.Element {
  return (
    <section>
      <div className="container">
        <div className="text--center">
          <Heading as="h2">Features</Heading>
          <p>
            SEGUL features operation on alignment, genomic-specific, and
            sequence datasets.
          </p>
        </div>
        <div className="row">
          {SupportedList.map((props, idx) => (
            <SupportedFeatures key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

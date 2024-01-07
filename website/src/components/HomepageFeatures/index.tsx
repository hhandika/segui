import clsx from "clsx";
import Heading from "@theme/Heading";
import styles from "./styles.module.css";

type FeatureItem = {
  title: string;
  Svg: React.ComponentType<React.ComponentProps<"svg">>;
  description: JSX.Element;
};

const FeatureList: FeatureItem[] = [
  {
    title: "Easy to Use",
    Svg: require("@site/static/img/easyUse.svg").default,
    description: (
      <>
        SEGUL offers an easy to use command command line interface. Prefer
        graphical interface? No problem, SEGUL also is also available as GUI
        (beta version).
      </>
    ),
  },
  {
    title: "Repeatable and Reproducible",
    Svg: require("@site/static/img/repeatableAndReproducible.svg").default,
    description: (
      <>
        SEGUL runs from smartphone to high-performance computers. It also
        generates log files that can be used to reproduce the results.
      </>
    ),
  },
  {
    title: "Fast and Memory Efficient",
    Svg: require("@site/static/img/fastMemoryEfficient.svg").default,
    description: (
      <>
        SEGUL is high-performance. It can process thousands of locus alignments
        on a computer with limited RAM.
      </>
    ),
  },
];

function Feature({ title, Svg, description }: FeatureItem) {
  return (
    <div className={clsx("col col--4")}>
      <div className="text--center">
        <Svg className={styles.featureSvg} role="img" />
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

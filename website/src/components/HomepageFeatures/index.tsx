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
        SEGUL offers an intuitive command line interface for efficient
        operation, along with a user-friendly, interactive graphical interface
        (currently in beta). Comprehensive documentation for both the
        application and the API ensures a seamless user experience.
      </>
    ),
  },

  {
    title: "Repeatable and Reproducible",
    Svg: require("@site/static/img/repeatableAndReproducible.svg").default,
    description: (
      <>
        SEGUL operates across a range of devices, from smartphones to
        high-performance computers, without requiring any runtime dependencies.
        It also negates the need for supplementary applications like Docker,
        enhancing its user-friendliness and accessibility.
      </>
    ),
  },
  {
    title: "Fast and Memory Efficient",
    Svg: require("@site/static/img/fastMemoryEfficient.svg").default,
    description: (
      <>
        SEGUL delivers high-speed performance while maintaining minimal memory
        usage. It’s engineered to leverage multi-core CPUs for rapid data
        processing, all without requiring manual intervention from the users.
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

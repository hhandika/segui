import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import Heading from "@theme/Heading";

import styles from "./index.module.css";
import HomepageScreenshot from "../components/HomepageScreenshot";

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--dark", styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--outline button--primary button--lg"
            to="/docs/intro/"
          >
            Learn SEGUL
          </Link>
          &nbsp;&nbsp;&nbsp;
          <Link
            className="button button--primary button--lg"
            to="/docs/installation/overview"
          >
            Install
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={siteConfig.tagline}
      description="SEGUL is an ultra-fast, lightweight tool for phylogenomics."
    >
      <HomepageHeader />
      <main>
        <HomepageFeatures />
        <HomepageScreenshot />
      </main>
    </Layout>
  );
}

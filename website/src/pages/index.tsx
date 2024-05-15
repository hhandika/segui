import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import Heading from "@theme/Heading";

import styles from "./index.module.css";
import HomepageScreenshot from "../components/HomepageScreenshot";
import DownloadOptions from "../components/DownloadButtons";


function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero hero--dark", styles.heroBanner)}>
      <div className="container">
        <div className="row row--no-gutters">
          <div className="col col--6"><HomepageScreenshot /></div>
          <div className="col col--6">
        <Heading as="h1" className={clsx("hero__title", styles.title)}>
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--primary button--lg"
            to="/docs/intro/"
          >
            Learn SEGUL
          </Link>
        </div>
        <Latest/>
        </div>
        </div>
      </div>
    </header>
  );
}

function Latest() {
  return (
      <div className={styles.whatsNew}>
        <Heading as="h2">
          Latest Updates
        </Heading>
        <p className={styles.newMessage}>
          <ul>
            <li>SEGUL GUI: Now in stable version! 🎉</li>
            <li>SEGUL CLI: Available as an ARM64 Linux binary.</li>
          </ul>
        </p>
      </div>
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
        <DownloadOptions />
      </main>
    </Layout>
  );
}

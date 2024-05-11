import clsx from "clsx";
import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import HomepageFeatures from "@site/src/components/HomepageFeatures";
import Heading from "@theme/Heading";

import styles from "./index.module.css";
import HomepageScreenshot from "../components/HomepageScreenshot";

enum OperatingSystem {
  Linux,
  MacOS,
  Windows,
  iOS,
  Android,
  unknown,
}

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
          <InstallButton />
        </div>
      </div>
    </header>
  );
}

function InstallButton() {
  let os: OperatingSystem;
  if (navigator.userAgent.includes("Linux")) {
    os = OperatingSystem.Linux;
  } else if (navigator.userAgent.includes("Mac OS")) {
    os = OperatingSystem.MacOS;
  } else if (navigator.userAgent.includes("Windows")) {
    os = OperatingSystem.Windows;
  } else if (navigator.userAgent.includes("iPhone") || navigator.userAgent.includes("iPad")) {
    os = OperatingSystem.iOS;
  } else if (navigator.userAgent.includes("Android")) {
    os = OperatingSystem.Android;
  } else {
    os = OperatingSystem.unknown;
  }

  let installButton: JSX.Element;
  switch (os) {
    case OperatingSystem.Linux:
      installButton = (
        <Link
          className="button button--primary button--lg"
          to="/docs/installation/linux"
        >
          Install on Linux
        </Link>
      );
      break;
    case OperatingSystem.MacOS:
      installButton = (
        <Link
          className="button button--primary button--lg"
          to="/docs/installation/macos"
        >
          Install on macOS
        </Link>
      );
      break;
    case OperatingSystem.Windows:
      installButton = (
        <Link
          className="button button--primary button--lg"
          to="/docs/installation/windows"
        >
          Install on Windows
        </Link>
      );
      break;
    case OperatingSystem.iOS:
      installButton = (
        <Link
          className="button button--primary button--lg"
          to="/docs/installation/ios"
        >
          Install on iOS
        </Link>
      );
      break;
    case OperatingSystem.Android:
      installButton = (
        <Link
          className="button button--primary button--lg"
          to="/docs/installation/android"
        >
          Install on Android
        </Link>
      );
      break;
    default:
      installButton = (
        <Link
          className="button button--primary button--lg"
          to="/docs/installation/overview"
        >
          Install
        </Link>
      );
  }

  return installButton;

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

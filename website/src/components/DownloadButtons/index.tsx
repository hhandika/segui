import Link from "@docusaurus/Link";
import Heading from "@theme/Heading";
import styles from "./styles.module.css";

function WindowsBadge(): JSX.Element {
  return (
    <Link to="https://apps.microsoft.com/detail/SEGUI/9np1bq6fw9pw?mode=direct/">
      <img
        src="https://get.microsoft.com/images/en-us%20dark.svg"
        width="200"
      />
    </Link>
  );
}

function GooglePlayBadge(): JSX.Element {
  return (
    <Link to="https://play.google.com/store/apps/details?id=com.hhandika.segui&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1">
      <img
        alt="Get it on Google Play"
        src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"
        height="80"
      />
    </Link>
  );
}


function DownloadOptions() {
  return (
    <div className={styles.install}>
      <Heading as="h2">Install SEGUL</Heading>
      <WindowsBadge />
      <GooglePlayBadge />
      <p><Link to="/docs/installation/overview" >Other install options</Link></p>
    </div>
  );
}


export default DownloadOptions;

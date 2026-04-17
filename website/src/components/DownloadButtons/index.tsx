import Link from "@docusaurus/Link";
import Heading from "@theme/Heading";
import styles from "./styles.module.css";
import { JSX } from "react";

function WindowsBadge(): JSX.Element {
  return (
    <Link to="https://apps.microsoft.com/detail/SEGUI/9np1bq6fw9pw?mode=direct/">
      <img
        className="margin-horiz--none margin-bottom--none"
        alt="Get it on Microsoft Store"
        src="https://get.microsoft.com/images/en-us%20dark.svg"
        width="168"
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
        height="72"
      />
    </Link>
  );
}

function MacStoreBadge(): JSX.Element {
  return (
    <Link to="https://apps.apple.com/us/app/segui/id6447999874?mt=12&amp;itsct=apps_box_badge&amp;itscg=30200">
      <img
        className="margin-horiz--sm margin-bottom--sm"
        src="https://tools.applemediaservices.com/api/badges/download-on-the-mac-app-store/black/en-us?size=250x83&amp;releaseDate=1716076800"
        alt="Download on the Mac App Store"
        width="200"
      />
    </Link>
  );
}

function AppStoreBadge(): JSX.Element {
  return (
    <Link to="https://apps.apple.com/us/app/segui/id6447999874?itsct=apps_box_badge&amp;itscg=30200">
      <img
        className="margin-horiz--none margin-bottom--sm"
        src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1716076800"
        alt="Download on the App Store"
        width="160"
      />
    </Link>
  );
}

function SnapStoreBadge(): JSX.Element {
  return (
    <Link to="https://snapcraft.io/segui">
      <img
        className="margin-horiz--none margin-bottom--sm"
        alt="Get it from the Snap Store"
        src="https://snapcraft.io/static/images/badges/en/snap-store-black.svg"
        width="168"
      />
    </Link>
  );
}

function DownloadOptions() {
  return (
    <div className={styles.install}>
      <Heading as="h2">Install SEGUL GUI</Heading>
      <p className="text--no-decoration">
        <WindowsBadge />
        <MacStoreBadge />
        <SnapStoreBadge />
      </p>
      <AppStoreBadge />
      <GooglePlayBadge />
      <p className="padding--none">
        <Link to="/docs/installation/intro">CLI & other install options</Link>
      </p>
    </div>
  );
}

export default DownloadOptions;

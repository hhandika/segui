import styles from "./styles.module.css";
import type { JSX } from "react";

export default function HomepageScreenshot(): JSX.Element {
  return (
    <section className={styles.screenshot}>
      <div className="container">
        <img
          className={styles.screenImg}
          src="/img/screenshots.png"
          alt="SEGUL homepage"
        />
      </div>
    </section>
  );
}

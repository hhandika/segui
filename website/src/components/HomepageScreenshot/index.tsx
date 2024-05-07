import styles from "./styles.module.css";

export default function HomepageScreenshot(): JSX.Element {
  return (
    <section className={styles.screenshot}>
      <div className="container">
        <img
          className={styles.screenImg}
          src="/img/ipadView.png"
          alt="SEGUL homepage"
        />
      </div>
    </section>
  );
}

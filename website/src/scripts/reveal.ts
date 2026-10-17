/// Fades `.sg-reveal` elements in as they scroll into view.
export function observeReveals(): void {
  const revealed = document.querySelectorAll<HTMLElement>(".sg-reveal");
  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  if (reduceMotion || !("IntersectionObserver" in window)) {
    revealed.forEach((element) => element.classList.add("sg-in"));
    return;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.classList.add("sg-in");
        observer.unobserve(entry.target);
      });
    },
    { rootMargin: "0px 0px -10% 0px", threshold: 0.1 },
  );
  revealed.forEach((element) => observer.observe(element));
}

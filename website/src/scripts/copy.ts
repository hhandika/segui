/// Wires `.sg-copy` buttons to copy their `data-copy` text to the clipboard.
export function bindCopyButtons(): void {
  document.querySelectorAll<HTMLButtonElement>(".sg-copy").forEach((button) => {
    if (button.dataset.bound) return;
    button.dataset.bound = "true";
    button.addEventListener("click", () => copy(button));
  });
}

async function copy(button: HTMLButtonElement): Promise<void> {
  const text = button.dataset.copy ?? "";
  const status = button.parentElement?.querySelector<HTMLElement>("[data-copy-status]");
  if (!(await writeClipboard(text))) {
    if (status) status.textContent = "Copy failed. Select the command to copy it.";
    return;
  }
  setState(button, "done");
  if (status) status.textContent = "Copied to clipboard";
  window.setTimeout(() => {
    setState(button, "idle");
    if (status) status.textContent = "";
  }, 1600);
}

/// Uses the Clipboard API, falling back to a hidden text area for browsers or
/// embedded views that block it.
async function writeClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch {
    const area = document.createElement("textarea");
    area.value = text;
    area.setAttribute("readonly", "");
    area.style.position = "fixed";
    area.style.opacity = "0";
    document.body.append(area);
    area.select();
    const copied = document.execCommand("copy");
    area.remove();
    return copied;
  }
}

function setState(button: HTMLButtonElement, state: "idle" | "done"): void {
  button.querySelectorAll<SVGElement>("[data-state]").forEach((icon) => {
    icon.classList.toggle("hidden", icon.dataset.state !== state);
  });
}

import { defineMarkdocConfig, component, Markdoc } from "@astrojs/markdoc/config";
import starlightMarkdoc from "@astrojs/starlight-markdoc";

const SCREENSHOT_SLOTS = ["large", "large2", "small", "small2"];

function validatePlacement(value) {
  const valid =
    Array.isArray(value) &&
    value.length === 2 &&
    value.every((n) => typeof n === "number" && n >= 0 && n <= 100);
  return valid
    ? []
    : [{ id: "pin-placement", level: "error", message: "Expected [x, y] percentages from 0 to 100" }];
}

export default defineMarkdocConfig({
  extends: [starlightMarkdoc()],
  tags: {
    // A GUI usage page's top figure: up to two large-screen and two small-screen
    // captures, with lettered `pin` children. Every pin must be placed on at
    // least one capture of each screen size, so readers find every element
    // whichever device they use. Pins are passed to the component as an array.
    screenshots: {
      render: component("./src/components/docs/UsageScreenshots.astro"),
      children: ["tag"],
      attributes: {
        large: { type: String, required: true },
        largeAlt: { type: String, required: true },
        large2: { type: String },
        large2Alt: { type: String },
        small: { type: String, required: true },
        smallAlt: { type: String, required: true },
        small2: { type: String },
        small2Alt: { type: String },
      },
      transform(node, config) {
        const attributes = node.transformAttributes(config);
        const pins = node.children
          .filter((child) => child.type === "tag" && child.tag === "pin")
          .map((child) => child.transformAttributes(config));
        return new Markdoc.Tag(this.render, { ...attributes, pins }, []);
      },
    },
    // One element shown in the figure. Each placement is `[x, y]` in percent of
    // that capture's width and height.
    pin: {
      selfClosing: true,
      attributes: {
        id: { type: String, required: true, matches: /^[A-Z]$/ },
        label: { type: String, required: true },
        ...Object.fromEntries(
          SCREENSHOT_SLOTS.map((slot) => [slot, { type: Array, validate: validatePlacement }]),
        ),
      },
      transform() {
        return null;
      },
    },
    // Inline letter linking text to a pin in the page's `screenshots` figure.
    ref: {
      render: component("./src/components/docs/ShotRef.astro"),
      inline: true,
      selfClosing: true,
      attributes: {
        id: { type: String, required: true, matches: /^[A-Z]$/ },
      },
    },
    // A fixed-width image, such as a store QR code.
    sizedimage: {
      render: component("./src/components/docs/SizedImage.astro"),
      selfClosing: true,
      attributes: {
        src: { type: String, required: true },
        alt: { type: String, required: true },
        width: { type: Number, required: true },
      },
    },
    storebadges: {
      render: component("./src/components/StoreBadges.astro"),
      selfClosing: true,
      attributes: {
        stores: { type: Array, required: true },
        tone: { type: String, matches: ["auto", "brand"] },
      },
    },
    benchmarks: {
      render: component("./src/components/cli-gui/Benchmarks.astro"),
      selfClosing: true,
      attributes: {
        chart: { type: String, required: true, matches: ["concat-time", "concat-ram", "tasks"] },
      },
    },
    guides: {
      render: component("./src/components/features/Guides.astro"),
      selfClosing: true,
      attributes: {
        feature: { type: String, required: true },
      },
    },
    rowselection: {
      render: component("./src/components/features/RowSelection.astro"),
      selfClosing: true,
      attributes: {
        id: { type: String, required: true },
        title: { type: String, required: true },
        caption: { type: String, required: true },
        rule: { type: String, required: true },
        verb: { type: String, required: true },
        rows: { type: Array, required: true },
        keep: { type: Array, required: true },
      },
    },
    sequenceids: {
      render: component("./src/components/features/SequenceIds.astro"),
      selfClosing: true,
      attributes: {
        map: { type: Boolean, default: false },
      },
    },
    // Diagrams and widgets without attributes.
    taskgroups: {
      render: component("./src/components/features/TaskGroups.astro"),
      selfClosing: true,
    },
    fileformats: {
      render: component("./src/components/features/FileFormats.astro"),
      selfClosing: true,
    },
    alignedvsunaligned: {
      render: component("./src/components/features/AlignedVsUnaligned.astro"),
      selfClosing: true,
    },
    alignmentsummary: {
      render: component("./src/components/features/AlignmentSummary.astro"),
      selfClosing: true,
    },
    concatenation: {
      render: component("./src/components/features/Concatenation.astro"),
      selfClosing: true,
    },
    conversion: {
      render: component("./src/components/features/Conversion.astro"),
      selfClosing: true,
    },
    distance: {
      render: component("./src/components/features/Distance.astro"),
      selfClosing: true,
    },
    filtering: {
      render: component("./src/components/features/Filtering.astro"),
      selfClosing: true,
    },
    fastqsummary: {
      render: component("./src/components/features/ReadSummary.astro"),
      selfClosing: true,
    },
    contigsummary: {
      render: component("./src/components/features/ContigSummary.astro"),
      selfClosing: true,
    },
    mafconversion: {
      render: component("./src/components/features/MafConversion.astro"),
      selfClosing: true,
    },
    mafsummary: {
      render: component("./src/components/features/MafSummary.astro"),
      selfClosing: true,
    },
    partitionconversion: {
      render: component("./src/components/features/PartitionConversion.astro"),
      selfClosing: true,
    },
    renaming: {
      render: component("./src/components/features/Renaming.astro"),
      selfClosing: true,
    },
    sequenceaddition: {
      render: component("./src/components/features/SequenceAddition.astro"),
      selfClosing: true,
    },
    splitting: {
      render: component("./src/components/features/Splitting.astro"),
      selfClosing: true,
    },
    translation: {
      render: component("./src/components/features/Translation.astro"),
      selfClosing: true,
    },
    transposition: {
      render: component("./src/components/features/Transposition.astro"),
      selfClosing: true,
    },
    trimming: {
      render: component("./src/components/features/Trimming.astro"),
      selfClosing: true,
    },
    unalignment: {
      render: component("./src/components/features/Unalignment.astro"),
      selfClosing: true,
    },
    commandmap: {
      render: component("./src/components/cli-gui/CommandMap.astro"),
      selfClosing: true,
    },
    featuresplit: {
      render: component("./src/components/cli-gui/FeatureSplit.astro"),
      selfClosing: true,
    },
    interfaceoverview: {
      render: component("./src/components/cli-gui/InterfaceOverview.astro"),
      selfClosing: true,
    },
    platformmatrix: {
      render: component("./src/components/cli-gui/PlatformMatrix.astro"),
      selfClosing: true,
    },
    readsummary: {
      render: component("./src/components/cli-gui/ReadSummary.astro"),
      selfClosing: true,
    },
    inputroutes: {
      render: component("./src/components/docs/InputRoutes.astro"),
      selfClosing: true,
    },
    mobileflow: {
      render: component("./src/components/docs/MobileFlow.astro"),
      selfClosing: true,
    },
    chooseinterface: {
      render: component("./src/components/quick-start/ChooseInterface.astro"),
      selfClosing: true,
    },
    clidownloads: {
      render: component("./src/components/quick-start/CliDownloads.astro"),
      selfClosing: true,
    },
    commandanatomy: {
      render: component("./src/components/quick-start/CommandAnatomy.astro"),
      selfClosing: true,
    },
    guisteps: {
      render: component("./src/components/quick-start/GuiSteps.astro"),
      selfClosing: true,
    },
  },
});

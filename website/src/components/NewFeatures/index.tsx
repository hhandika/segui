import { JSX } from "react";

function NewFeatures(): JSX.Element {
  return (
    <div className="m-4">
      <div className="max-w-6xl mx-auto my-12 border rounded-xl bg-white dark:bg-gray-800 p-6 overflow-hidden">
        <div className="text-center mb-8">
          <h2>What's New in SEGUL v0.23.0</h2>
        </div>

        <div className="space-y-6">
          <div>
            <h3>New Features 🚀</h3>
            <ul>
              <li>
                <a href="/docs/cli-usage/align-unalign">
                  Convert alignments to unaligned sequences
                </a>
              </li>
              <li>
                <a href="/docs/cli-usage/sequence-add">
                  Add sequence to an existing sequence files/alignments
                </a>
              </li>
              <li>
                <a href="/docs/cli-usage/align-trim">Trim alignments</a>
              </li>
              <li>
                New options for filtering alignments (
                <a href="/docs/cli-usage/align-filter">see details</a>):
                <ul>
                  <li>Minimum or maximum sequence length</li>
                  <li>Minimum or maximum of parsimony informative sites</li>
                  <li>Minimum taxon counts</li>
                  <li>Based on user-defined list of sequence IDs</li>
                </ul>
              </li>
            </ul>
          </div>

          <div>
            <h3>Breaking Changes ⚠️</h3>
            <ul>
              <li>
                Filtering argument changes for better consistency (see{" "}
                <a href="/docs/cli-usage/align-filter">docs</a>)
              </li>
              <li>
                Remove <code>--ntax</code> option from{" "}
                <a href="/docs/cli-usage/align-filter">alignment filtering</a>{" "}
                because by default SEGUL automatically and fastly counts the
                number of unique taxa across all input alignments
              </li>
            </ul>
          </div>

          <div>
            <h3>Bug Fixes 🐛</h3>
            <ul>
              <li>Fix max-gap filtering issues</li>
              <li>
                Fix concatenation leading to missing data when sequence IDs in
                FASTA files contain trailing whitespace
              </li>
            </ul>
          </div>

          <div>
            <h3>Other Changes 🛠</h3>
            <ul>
              <li>Migrate to Rust 2024 edition</li>
              <li>Update dependencies</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}

export default NewFeatures;

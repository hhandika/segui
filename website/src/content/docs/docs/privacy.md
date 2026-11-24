---
title: Privacy Policy
sidebar:
  order: 12
---

## Introduction

This Privacy Policy describes how SEGUL (“we”, “us”, or “our”) handles information when you use the SEGUI app, the SEGUL command-line tool, the SEGUL libraries (`segul-core` and `pysegul`), or visit our website, [segul.app](https://segul.app).

## Your Data Stays on Your Device

SEGUL and SEGUI do all their analyses on your device. The sequence files, alignments, and other data you open are read and written only on your device, or on the computer or cluster where you run SEGUL. They are never uploaded to us or to anyone else.

## Information We Collect

We do not collect any personal information. The SEGUI app, the SEGUL command-line tool, and the SEGUL libraries do not include analytics, advertising, tracking, or crash reporting. The SEGUL command-line tool does not connect to the internet. SEGUI and the optional `download` feature of `segul-core` connect only when you search or download from public sequence databases, described below.

SEGUI keeps your settings, such as the theme and an optional NCBI API key, on your device. SEGUL writes a log file (`segul.log` by default) next to your output. Neither is sent to us.

SEGUI opens links, such as the documentation, in your web browser, and shares output files only when you choose to share them.

## Database Searches and Downloads

When you use **Search databases** in SEGUI, the app connects directly over HTTPS to the [National Center for Biotechnology Information (NCBI)](https://www.ncbi.nlm.nih.gov/home/about/policies/) for GenBank and to [EMBL-EBI](https://www.ebi.ac.uk/about/terms-of-use/) for the European Nucleotide Archive, whichever you choose.

They receive your search terms, including organism names as you type them for suggestions, the accessions you look up or download, and your IP address, as with any internet request. Requests to NCBI also include the app name and a developer contact address as requested by NCBI policy, never your own email address. Both archives handle requests under their own policies. SEGUI does not send this information to us and never uploads your files.

If you add an optional NCBI API key in **Settings › Databases**, SEGUI stores it only on your device and sends it over HTTPS only to NCBI (`eutils.ncbi.nlm.nih.gov`) to raise the GenBank rate limit. It is never sent to us or to EMBL-EBI, and it is not written to `sources.tsv` or log files. You can remove the key at any time in **Settings › Databases** (**Clear**), and you can delete downloaded files in **Settings › Data usage**.

## Crash Reports from App Stores

If you allow it in your device settings, Apple (App Store), Google (Google Play), or Microsoft (Microsoft Store) may share anonymous crash reports and usage statistics with us. These reports do not identify you, and we use them only to fix problems in the app. You can turn this sharing off in your device settings at any time.

## Website

Our website is hosted on [Cloudflare](https://www.cloudflare.com/privacypolicy/). Like any web host, Cloudflare processes your IP address and the details of each request, such as the page and your browser, to deliver the website and protect it from abuse.

We use [Cloudflare Web Analytics](https://www.cloudflare.com/web-analytics/) to count page views. It does not use cookies or track you across websites, and it does not give us information that identifies you. We see only aggregate statistics, such as the pages visited, the referring website, and the browser, operating system, device type, and country of visitors. We use these statistics only to understand which documentation is useful and to improve the website.

## Third-Party Services

SEGUL and SEGUI are distributed through third parties, including the App Store, Google Play, Microsoft Store, GitHub, Bioconda, crates.io, and PyPI. The install script on our website downloads SEGUL from GitHub. These services handle your information under their own privacy policies.

## Contacting Us

If you email us or open an issue on GitHub, we receive the information you include, such as your email address or GitHub username. We use it only to respond to you.

## Children's Privacy

Because we do not collect personal information, we do not knowingly collect personal information from children.

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will post the new Privacy Policy on this page.

## Contact Us

If you have any questions about this Privacy Policy, please contact us at [support@segul.app](mailto:support@segul.app).

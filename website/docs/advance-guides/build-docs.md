---
sidebar_position: 3
title: Building SEGUL Documentation
description: Guides on building SEGUL documentation.
---

SEGUL documentation is built using docusaurus and deployed using [Vercel](https://vercel.com/). The documentation is written in markdown and the website is built using React written in TypeScript.

## Prerequisites

- [Node.js](https://nodejs.org/en/)
- [Yarn](https://yarnpkg.com/getting-started/install)
- [Git](https://git-scm.com/downloads)
- [GH CLI (recommended)](https://cli.github.com/)

## Clone the repository

```bash
gh repo clone hhandika/segui
```

Using git:

```bash
git clone https://github.com/hhandika/segui.git
```

## Install dependencies

Install nodejs:

It is recommended to use a package manager to install nodejs. Two common options are [NVM](https://github.com/nvm-sh/nvm) and [fnm](https://github.com/Schniz/fnm). We recommend using fnm for its speed and simplicity.

Using fnm:

```bash
curl -fsSL https://fnm.vercel.app/install | bash
```

After installing fnm, restart your terminal and install the latest LTS version of Node.js:

```bash
fnm install --lts
```

Check the installed version of Node.js:

```bash
node -v
npm -v
```

Activate yarn package manager:

```bash
corepack enable
```

Change directory to the website folder:

```bash
cd segui/website
```

Install docusaurus dependencies:

```bash
yarn install
```

## Run the website

To run the website locally, use the following command:

```bash
yarn start
```

The website will be available at `http://localhost:3000/`.

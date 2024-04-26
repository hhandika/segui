---
sidebar_position: 4
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

First, intall nodejs by following the instructions [here](https://nodejs.org/en/)

We recommend using yarn to install the dependencies:

```bash
npm install -g yarn
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

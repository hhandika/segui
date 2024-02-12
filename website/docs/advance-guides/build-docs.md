---
sidebar_position: 2
title: Building SEGUL Documentation
---

## Overview

SEGUL documentation is built using docusaurus. The documentation is written in markdown and the website is built using TypeScript with React.

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

Install the dependencies:

Install nodejs dependencies:

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

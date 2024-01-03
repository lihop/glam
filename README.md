<!--
  SPDX-FileCopyrightText: 2021 Leroy Hopson <glam@leroy.geek.nz>
  SPDX-License-Identifier: MIT
-->

<img align="left" width="64" height="64" src="icon.png">

# GLAM
```
Godot Libre Asset Manager
```

Godot plugin for finding, downloading and managing free, libre, and creative commons assets. Work in progress.

## Goals

### 1. Quick prototyping.

It can be quite tedious to download assets, unzip them, copy their files over to your Godot project and then setup resources to use the files. GLAM aims to make it easy to download and setup assets with a single click and then drag them directly into the scene or inspector. This can be useful if you want to quickly try out many different assets, or want to work quickly, such as in a game jam.

### 2. Keep track of licenses and attribution.

Many free asset licenses require attribution as part of their requirements and keeping track of license and attribution information can also be quite tedious. GLAM aims to make this easy by following the [reuse specification](https://reuse.software/spec/) and creating `.license` files along side downloaded assets that also include additional metadata such as author profile urls, original titles, and download sources. These files can then be used to automatically generate credits that can be added to the documentation or shown in-game.

## Sources

GLAM offers (or plans to offer) integration with the APIs of the following sources.
Some of these sources require an api account to use (see 'Account Required').

| Source                                     | Account Required | Support     | Notes                                                |
|--------------------------------------------|------------------|-------------|------------------------------------------------------|
| [AmbientCG](https://ambientcg.com)         | No               | Partial     | Currently only PBR textures. No search filters       |
| [Pixabay](https://pixabay.com)             | Yes              | Partial     | Currently only images (no videos). No search filters |
| [Freesound](https://freesound.org)         | Yes              | In progress | Sound Effects                                        |
| [Openclipart](https://openclipart.org)     | Yes              | Planned     | Vector Graphics                                      |
| [FreeSVG](https://freesvg.org)             | Yes              | Planned     | Vector Graphics                                      |
| [Noun Project](https://thenounproject.com) | Yes              | Planned     | Icons, Images                                        |
| [Poly Haven](https://polyhaven.com)        | No               | Planned     | PBR Textures, 3D Models, HDRs                        |
| [Sketchfab](https://sketchfab.com)         | Yes              | Planned     | 3D Models                                            |
| [Jamendo](https://www.jamendo.com)         | Yes              | Planned     | Music                                                |
| [ccMixter](http://ccmixter.org)            | No               | Planned     | Music                                                |
| [SoundCloud](http://soundcloud.com)        | Yes              | Planned     | Music                                                |

## Installation

Copy the `addons/glam` directory in this repo to your Godot project.

Or install the [gd-plug](https://godotengine.org/asset-library/asset/962) plugin. By adding the following to your `plug.gd` file (changing the commit hash to the version of GLAM you want to use):

```gdscript
plug("lihop/glam", {tag = "0.1.0", include = ["addons/glam"]})
```

## Screenshots

![3D Editor with Ambient CG textures](/docs/texture_search.jpg)
![Vector images from Pixabay](/docs/vector_search.jpg)
![Images of mountains from Pixabay](/docs/image_search.jpg)
![Audio files of fire crackling from Freesound](/docs/audio_search.jpg)

## Developing

If you've cloned this repository and wish to contribute or work on it, you should know that we use [just](https://just.systems/man/en/) as command runner and [pre-commit](https://pre-commit.com/) for automated code formatting (it's run tools like codespell, reuse, gdformat).

> [!NOTE]
> For more details on each tool, including installation instructions and usage guidelines, refer to their official documentation.

### Installing plugins

Before diving into development, make sure to install the required plugins using the following command:

```shell
godot --no-window -s plug.gd install
# or: just install-addons
```

### Testing

GLAM uses [Gut](https://github.com/bitwes/Gut) as testing framework.

To run tests from the command line, use the following commands:

```shell
godot --no-window -s addons/gut/gut_cmdln.gd
# or: just unit
```

By default, only unit tests will be run.

To run all tests (including integration tests) use:

```shell
godot --no-window -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig_all.json
# or: just integration
```

> [!IMPORTANT]
> Integration tests require [python](https://www.python.org/) to be installed to start an [http.server](https://docs.python.org/3/library/http.server.html) HTTP server. The integration tests also take a long time (more than 30 seconds) to run.

### Continuous Integration

We use [GitHub Actions](https://docs.github.com/en/actions) for continuous integration, ensuring that code changes are validated and tested on each push. The workflow tests the addon on each plaftform and several last major versions of Godot. Check the [`.github/workflows/main.yml`](./.github/workflows/main.yml) file for details on the CI workflow.

### Continuous Delivery

Whenever a tag is pushed, the main workflow triggers a `publish` step, creating a GitHub release. This automated process simplifies the release management. But before tagging the code, make sure the version in the [`.env`](./.env) is correctly bumped.

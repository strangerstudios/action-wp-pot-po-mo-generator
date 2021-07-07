# WordPress POT/PO/MO Generator - GitHub Action

This Action generates the .pot, .po, and .mo files for your WordPress plugin or theme repository.

## Configuration
### Required secrets
* `GITHUB_TOKEN`

[Secrets are set in your repository settings](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets). They cannot be viewed once stored.

### Other optional configuration

| Key | Default | Description |
| --- | ------- | ----------- |
| `destination_path` | `./languages` | Destination path to save generated files. |
| `slug` | The GitHub repository name | Plugin or theme slug. |
| `text_domain` | The plugin or theme slug | Text domain to look for in the source code. |
| `generate_pot` | `1` | Whether to generate the .pot file. |
| `generate_po` | `0` | Whether to generate the .po file. |
| `generate_mo` | `0` | Whether to generate the .mo file. |
| `generate_lang_packs` | `0` | Whether to generate the .po/.mo language packs. |
| `merge_changes` | `0` | Whether to merge changes with existing files. |
| `headers` | `{}` | Additional headers in JSON format to use when generating files. |

## Workflow files

To get started, you will want to copy the contents of one of these examples into `.github/workflows/generate-translations.yml` and push that to your repository. You are welcome to name the file something else.

## Example Workflow File (Pushes)

### Super simple workflow

This only generates the .pot file in the /languages folder.

```yml
name: Generate Translations
on:
  push:
    branches:
      - develop

jobs:
  generate-translations:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: WordPress POT/PO/MO Generator
      uses: strangerstudios/action-wp-pot-po-mo-generator@main
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Customize certain options

```yml
name: Generate Translations
on:
  push:
    branches:
      - develop

jobs:
  generate-translations:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: WordPress POT/PO/MO Generator
      uses: strangerstudios/action-wp-pot-po-mo-generator@main
      with:
        destination_path: './languages'
        slug: 'SLUG_OF_PLUGIN_OR_THEME'
        text_domain: 'TEXT_DOMAIN_OF_PLUGIN_OR_THEME'
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Example Workflow File (On Demand)

For more details of how to use this action on demand, read up on [Manual Triggers](https://github.blog/changelog/2020-07-06-github-actions-manual-triggers-with-workflow_dispatch/).

```yml
name: Generate Translations
on: workflow_dispatch
jobs:
  generate-translations:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: WordPress POT/PO/MO Generator
      uses: strangerstudios/action-wp-pot-po-mo-generator@main
      with:
        destination_path: './languages'
        slug: 'SLUG_OF_PLUGIN_OR_THEME'
        text_domain: 'TEXT_DOMAIN_OF_PLUGIN_OR_THEME'
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Credits

This action is based on [this script](https://gist.github.com/ipokkel/e67c4e6133d58ab39048fbed6e47f8bc) by Theunis Coetzee ([@ipokkel](https://github.com/ipokkel)) and [this action](https://github.com/iamdharmesh/action-wordpress-pot-generator) by Dharmesh Patel ([@iamdharmesh](https://github.com/iamdharmesh))

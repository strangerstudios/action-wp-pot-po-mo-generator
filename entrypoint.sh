#!/bin/bash
set -e

# ==============================================================
# Language File Creator
# Authors: Theunis Coetzee (ipokkel), Scott Kingsley Clark (sc0ttkclark)
# Original script: https://gist.github.com/ipokkel/e67c4e6133d58ab39048fbed6e47f8bc
# Also based on: https://github.com/iamdharmesh/action-wordpress-pot-generator
#
# If no existing language template file (*.pot) exists, create it and
# default .po and .mo, otherwise,
# Give user the option to merge old template with new (updates default po & mo also).
#
# Check if there's existing language packe, e.g. text-domain-fr_FR, and
# give user the option to update and merge.
# ==============================================================

# Set options based on user input and handle defaults.

if [ -z "$INPUT_DESTINATION_PATH" ]; then
	WP_PPM_DESTINATION_PATH="./languages"
else
	WP_PPM_DESTINATION_PATH=$INPUT_DESTINATION_PATH
fi

if [ -z "$INPUT_SLUG" ]; then
	WP_PPM_SLUG=${GITHUB_REPOSITORY#*/}
else
	WP_PPM_SLUG=$INPUT_SLUG
fi

if [ -z "$INPUT_TEXT_DOMAIN" ]; then
	WP_PPM_TEXT_DOMAIN=$WP_PPM_SLUG
else
	WP_PPM_TEXT_DOMAIN=$INPUT_TEXT_DOMAIN
fi

if [ -z "$INPUT_GENERATE_POT" ] || [ "$INPUT_GENERATE_POT" == "1" ]; then
	WP_PPM_GENERATE_POT=true
else
	WP_PPM_GENERATE_POT=false
fi

if [ -z "$INPUT_GENERATE_PO" ] || [ "$INPUT_GENERATE_PO" != "1" ]; then
	WP_PPM_GENERATE_PO=false
else
	WP_PPM_GENERATE_PO=true
fi

if [ -z "$INPUT_GENERATE_MO" ] || [ "$INPUT_GENERATE_MO" != "1" ]; then
	WP_PPM_GENERATE_MO=false
else
	WP_PPM_GENERATE_MO=true
fi

if [ -z "$INPUT_GENERATE_LANG_PACKS" ] || [ "$INPUT_GENERATE_LANG_PACKS" != "1" ]; then
	WP_PPM_GENERATE_LANG_PACKS=false
else
	WP_PPM_GENERATE_LANG_PACKS=true
fi

if [ -z "$INPUT_MERGE_CHANGES" ] || [ "$INPUT_MERGE_CHANGES" == "0" ]; then
	WP_PPM_MERGE_CHANGES=""
else
	WP_PPM_MERGE_CHANGES="--merge"
fi

if [ -z "$INPUT_HEADERS" ]; then
	WP_PPM_HEADERS="{}"
else
	WP_PPM_HEADERS=$INPUT_HEADERS
fi

if [ -z "$PAT_TOKEN" ]; then
	WP_PPM_TOKEN=$GITHUB_TOKEN
else
	WP_PPM_TOKEN=$PAT_TOKEN
fi

# Define file paths.
WP_PPM_POT_PATH="$WP_PPM_DESTINATION_PATH/$WP_PPM_TEXT_DOMAIN.pot"
WP_PPM_PO_PATH="$WP_PPM_DESTINATION_PATH/$WP_PPM_TEXT_DOMAIN.po"
WP_PPM_MO_PATH="$WP_PPM_DESTINATION_PATH/$WP_PPM_TEXT_DOMAIN.mo"
WP_PPM_LANG_PACKS_BASE_PATH="$WP_PPM_DESTINATION_PATH/$WP_PPM_TEXT_DOMAIN"

echo "========================================"
echo "========================================"
echo "== WP POT/PO/MO Generator =============="
echo "========================================"
echo "========================================"
echo ""

# Output information from this run.
echo "* GITHUB_EVENT_NAME: $GITHUB_EVENT_NAME"
echo "* GITHUB_EVENT_PATH: $GITHUB_EVENT_PATH"
echo "* WP_PPM_DESTINATION_PATH: $WP_PPM_DESTINATION_PATH"
echo "* WP_PPM_SLUG: $WP_PPM_SLUG"
echo "* WP_PPM_TEXT_DOMAIN: $WP_PPM_TEXT_DOMAIN"
echo "* WP_PPM_POT_PATH: $WP_PPM_POT_PATH"
echo "* WP_PPM_PO_PATH: $WP_PPM_PO_PATH"
echo "* WP_PPM_MO_PATH: $WP_PPM_MO_PATH"
echo "* WP_PPM_LANG_PACKS_BASE_PATH: $WP_PPM_LANG_PACKS_BASE_PATH"

WP_PPM_REPO_NAME="$GITHUB_REPOSITORY"
WP_PPM_REMOTE="origin"
WP_PPM_IS_FORK=false

# Handle pull requests.
if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
	WP_PPM_IS_FORK=$(< "$GITHUB_EVENT_PATH" jq .pull_request.head.repo.fork)
	WP_PPM_CAN_MODIFY_PR=$(< "$GITHUB_EVENT_PATH" jq .pull_request.maintainer_can_modify)

	# Handle forks.
	if [ "$WP_PPM_IS_FORK" == true ]; then
		WP_PPM_REPO_NAME=$(< "$GITHUB_EVENT_PATH" jq .pull_request.head.repo.full_name | cut -d "\"" -f 2)
		WP_PPM_REMOTE=$(< "$GITHUB_EVENT_PATH" jq .pull_request.head.repo.clone_url | cut -d "\"" -f 2)
	fi

	# Check if we can continue.
	if [ "$WP_PPM_IS_FORK" == true ] && [ "$WP_PPM_CAN_MODIFY_PR" == false ]; then
		echo "🚫 PR cannot be modified by maintainer"

		exit 1
	fi

	# Output more information that we just added.
	echo "* WP_PPM_IS_FORK: $WP_PPM_IS_FORK"
	echo "* WP_PPM_CAN_MODIFY_PR: $WP_PPM_CAN_MODIFY_PR"
fi

# Output more information that we have.
echo "* WP_PPM_REMOTE: $WP_PPM_REMOTE"
echo "* GITHUB_REF: $GITHUB_REF"
echo "* GITHUB_HEAD_REF: $GITHUB_HEAD_REF"

echo ""
echo "========================================"
echo ""

echo "Checking destination path..."

# Maybe create the destination path.
if [ ! -d "$WP_PPM_DESTINATION_PATH" ]; then
	echo "🔨 Creating path: $WP_PPM_DESTINATION_PATH"
	mkdir -p "$WP_PPM_DESTINATION_PATH"
	echo "✅ Created path"
else
	echo "🆗️ Path found: $WP_PPM_DESTINATION_PATH"
fi

echo "Setting git config..."

# Setup Git config.
git config --global user.name "WordPress POT/PO/MO Generator"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global --add safe.directory /github/workspace

echo "::group::Setting up repo..."

if [ -z "$GITHUB_HEAD_REF" ]; then
  # It's already checked out for manual dispatches and other cases where branch is not set.
  echo "🆗️ Git already checked out to correct branch"

  echo ""
  echo "== Running: git pull ==================="
  echo ""

  # Fetch the latest from the branch.
  git pull
else
  # Checkout to PR branch.
  echo "🔨 Fetching remote and checking out"

  git config "branch.$GITHUB_HEAD_REF.remote" "$WP_PPM_REMOTE"
  git config "branch.$GITHUB_HEAD_REF.merge" "refs/heads/$GITHUB_HEAD_REF"

  echo ""
  echo "== Running: git checkout ==============="
  echo ""

  git checkout "$GITHUB_HEAD_REF"
fi

echo "::endgroup::"

echo "::group::Generating Files"

# Maybe generate POT file.
if [ "$WP_PPM_GENERATE_POT" == true ]; then
	echo "🔨 Generating the .pot file: $WP_PPM_POT_PATH"

  echo ""
  echo "== Running: wp i18n make-pot ==========="
  echo ""

	wp i18n make-pot . "$WP_PPM_POT_PATH" --domain="$WP_PPM_TEXT_DOMAIN" --slug="$WP_PPM_SLUG" --headers="$WP_PPM_HEADERS" --allow-root --color

  echo ""
  echo "========================================"
  echo ""

	# Maybe add file to repository.
	if [ "$(git status "$WP_PPM_POT_PATH" --porcelain)" != "" ]; then
		echo "➕ Adding the .pot file to the repository"
		git add "$WP_PPM_POT_PATH"
		echo "✅ Added the .pot file to the repository"
	else
		echo "🆗️ No changes made to the .pot file"
	fi
else
	echo "⏭ Skipping generating the .pot file"
fi

echo ""
echo "========================================"
echo ""

# Maybe generate PO file.
if [ "$WP_PPM_GENERATE_PO" == true ]; then
	echo "🔨 Generating the .po file: $WP_PPM_PO_PATH"

  echo ""
  echo "== Running: wp i18n make-pot ==========="
  echo ""

	wp i18n make-pot . "$WP_PPM_PO_PATH" --domain="$WP_PPM_TEXT_DOMAIN" --slug="$WP_PPM_SLUG" --headers="$WP_PPM_HEADERS" $WP_PPM_MERGE_CHANGES --allow-root --color

  echo ""
  echo "========================================"
  echo ""

	# Maybe add file to repository.
	if [ "$(git status "$WP_PPM_PO_PATH" --porcelain)" != "" ]; then
		echo "➕ Adding the .po file to the repository"
		git add "$WP_PPM_PO_PATH"
		echo "✅ Added the .po file to the repository"
	else
		echo "🆗️ No changes made to the .po file"
	fi
else
	echo "⏭ Skipping generating the .po file"
fi

echo ""
echo "========================================"
echo ""

# Maybe generate MO file.
if [ "$WP_PPM_GENERATE_MO" == true ]; then
	echo "🔨 Generating the .mo file: $WP_PPM_MO_PATH"

  echo ""
  echo "== Running: wp i18n make-mo ============"
  echo ""

	wp i18n make-mo "$WP_PPM_PO_PATH" "$WP_PPM_DESTINATION_PATH" --allow-root --color

  echo ""
  echo "========================================"
  echo ""

	# Maybe add file to repository.
	if [ "$(git status "$WP_PPM_MO_PATH" --porcelain)" != "" ]; then
		echo "➕ Adding the .mo file to the repository"
		git add "$WP_PPM_MO_PATH"
		echo "✅ Added the .mo file to the repository"
	else
		echo "🆗️ No changes made to the .mo file"
	fi
else
	echo "⏭ Skipping generating the .mo file"
fi

echo "::endgroup::"

echo "::group::Generating Language Packs"

# Use nullglob in case there are no matching files.
shopt -s nullglob

# Maybe update the language packs.
if [ "$WP_PPM_GENERATE_LANG_PACKS" != "" ]; then
  WP_PPM_LANG_PACKS=(${WP_PPM_LANG_PACKS_BASE_PATH}-*.po)
  WP_PPM_LANG_PACKS_COUNT=${#WP_PPM_LANG_PACKS[@]}

  echo "ℹ️ Found $WP_PPM_LANG_PACKS_COUNT language pack(s) to generate"

  if [ "$WP_PPM_LANG_PACKS_COUNT" != 0 ]; then
    for WP_PPM_LANG_PACK_PO in "${WP_PPM_LANG_PACKS[@]}"; do
      echo ""
      echo "========================================"
      echo ""

      echo "🔨 Generating the language pack .po: $WP_PPM_LANG_PACK_PO"

      echo ""
      echo "== Running: wp i18n make-pot ==========="
      echo ""

      wp i18n make-pot . "$WP_PPM_LANG_PACK_PO" --domain="$WP_PPM_TEXT_DOMAIN" --slug="$WP_PPM_SLUG" --headers="$WP_PPM_HEADERS" $WP_PPM_MERGE_CHANGES --allow-root --color

      echo ""
      echo "========================================"
      echo ""

      # Maybe add file to repository.
      if [ "$(git status "$WP_PPM_LANG_PACK_PO" --porcelain)" != "" ]; then
        echo "➕ Adding the language pack .po file to the repository"
        git add "$WP_PPM_LANG_PACK_PO"
        echo "✅ Added the language pack .po file to the repository"
      else
        echo "🆗️ No changes made to the language pack .po file"
      fi

      echo ""
      echo "========================================"
      echo ""

      WP_PPM_LANG_PACK_MO="${WP_PPM_LANG_PACK_PO%.po}.mo"

      echo "🔨 Generating the language pack .mo: $WP_PPM_LANG_PACK_MO"

      echo ""
      echo "== Running: wp i18n make-mo ============"
      echo ""

      wp i18n make-mo "$WP_PPM_LANG_PACK_PO" "$WP_PPM_DESTINATION_PATH" --allow-root --color

      echo ""
      echo "========================================"
      echo ""

      # Maybe add file to repository.
      if [ "$(git status "$WP_PPM_LANG_PACK_MO" --porcelain)" != "" ]; then
        echo "➕ Adding the language pack .mo file to the repository"
        git add "$WP_PPM_LANG_PACK_MO"
        echo "✅ Added the language pack .mo file to the repository"
      else
        echo "🆗️ No changes made to the language pack .mo file"
      fi
    done
  fi
else
	echo "⏭ Skipping language pack generation"
fi

echo "::endgroup::"

echo "::group::Doing Git things with Git"

# Commit the changes.
echo "🔼 Committing and pushing change(s) to repository"

echo ""
echo "== Running: git commit ================="
echo ""

git commit --allow-empty -m "🔄 Regenerate translation files"

echo ""
echo "== Running: git push ==================="
echo ""

if [ "$WP_PPM_IS_FORK" == true ]; then
  # Handle forks.
	git config credential.https://github.com/.helper "! f() { echo username=x-access-token; echo password=$WP_PPM_TOKEN; };f"
	git push "https://x-access-token:$WP_PPM_TOKEN@github.com/$WP_PPM_REPO_NAME"
else
  # Handle normal checkouts.
	git push "https://x-access-token:$GITHUB_TOKEN@github.com/$WP_PPM_REPO_NAME"
fi

echo ""
echo "========================================"
echo ""

echo "✅ All changes committed and pushed to repository"

echo "::endgroup::"

echo "✅ Completed successfully"

# Successful run.
exit 0

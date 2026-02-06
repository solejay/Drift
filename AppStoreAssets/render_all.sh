#!/usr/bin/env bash
#
# render_all.sh -- Generate all five App Store marketing screenshots.
#
# Prerequisites:
#   pip install Pillow
#   (or use: uv run --with Pillow python render_screenshots.py ...)
#
# Place raw simulator screenshots in AppStoreAssets/screenshots/ and then
# run this script from anywhere -- it cd's into AppStoreAssets first.
#
set -euo pipefail

# Navigate to the directory this script lives in (AppStoreAssets/)
cd "$(dirname "$0")"

# Ensure the output directory exists
mkdir -p marketing

echo "==> Rendering marketing screenshots..."

python3 render_screenshots.py \
    --input  screenshots/01-spending-overview.png \
    --output marketing/01-spending-overview.png \
    --headline "Your daily spending mirror" \
    --subtitle "See where your money quietly drifts"

python3 render_screenshots.py \
    --input  screenshots/02-leaky-buckets.png \
    --output marketing/02-leaky-buckets.png \
    --headline "Find your hidden leaks" \
    --subtitle "Small patterns that quietly add up"

python3 render_screenshots.py \
    --input  screenshots/03-onboarding.png \
    --output marketing/03-onboarding.png \
    --headline "No budgets. No guilt." \
    --subtitle "Just daily awareness that changes habits"

python3 render_screenshots.py \
    --input  screenshots/04-settings.png \
    --output marketing/04-settings.png \
    --headline "Your app, your way" \
    --subtitle "Secure, private, and personalized"

python3 render_screenshots.py \
    --input  screenshots/05-transaction-detail.png \
    --output marketing/05-transaction-detail.png \
    --headline "Every transaction, crystal clear" \
    --subtitle "Tap any purchase for the full picture"

echo "==> Done. Marketing screenshots saved to marketing/"

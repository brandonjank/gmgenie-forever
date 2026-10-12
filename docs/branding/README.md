# GMGenie Forever artwork

Original artwork created for this project with the built-in OpenAI image
generation tool. Distributed with the addon under GPL-3.0.

- `gmgenie-forever-source.png`: original generated artwork.
- `icon.png`: 512 x 512 PNG for web use.
- `social-preview.png`: 640 x 640 PNG, under 1 MB, ready for GitHub social preview.
- `../../Textures/Forever.tga`: 128 x 128 uncompressed RGB TGA for the WoW client.
- `../../.previews/GMGenie-Forever.png`: release-branch image for WowUpHub previews.

## WowUp setup

In GitHub repository Settings > General > Social preview > Edit > Upload an
image, select `social-preview.png`. WowUpHub documents using this repository
social preview as the default image, with the owner avatar as fallback.
The `.previews` directory provides gallery images from the tagged release branch.

The direct GitHub importer in the installed WowUp 2.24.0-beta.6 CF uses
`repository.owner.avatar_url` for its thumbnail. It does not read an icon field
from `release.json`. Adding an unsupported field will not replace that avatar.
A Hub listing is needed to use the documented Hub image behavior; it has not
been registered or verified for this project. Current GitHub imports continue
to receive updates normally.

References:
- https://wowup.io/guide/wowup/hub
- https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview

## Generation prompt

Use case: logo-brand. Create one polished square icon for GMGenie Forever, a
World of Warcraft private-server game master toolbox. Original hand-painted
fantasy game inventory icon: a bold antique brass genie lamp in three-quarter
view across the lower half, a single luminous violet magical smoke ribbon rising
from its spout and forming a clear infinity symbol in the upper half. Deep
midnight-indigo background, warm golden rim lighting, saturated violet and a
subtle cyan highlight. Thick clear silhouette and strong contrast, readable at
48 by 48 pixels. Keep the entire emblem comfortably within the square with 10%
safe padding. Restrained ornament, beautifully painted metal, no tiny intricate
background details. Full-bleed square background, no rounded app tile, no
surrounding frame. No text, letters, watermark, recognizable existing logo,
characters or UI mockup. Output the icon artwork alone.

The PNG sizes and TGA were exported from the generated source without creative
modifications.

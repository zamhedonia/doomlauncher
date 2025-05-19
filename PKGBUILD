# Maintainer: Zamhedonia <zamhedonia@gmx.de>
pkgname=doomlauncher
pkgver=1.1
pkgrel=1
pkgdesc="Simple terminal launcher for GZDoom with dialog UI"
arch=('any')
url="https://github.com/zamhedonia/doomlauncher"
license=('MIT')
depends=('dialog')
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/zamhedonia/doomlauncher/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('9c2645118e3f9a0aa6a0fbccc829824e769c3a3be52121bc4de6fa7bcb1457cd')

package() {
    cd "${srcdir}/${pkgname}-${pkgver}"

    # Install main script
    install -Dm755 doomlauncher.sh "${pkgdir}/usr/bin/doomlauncher"

    # Install the LICENSE file
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"

    # Install config andtheme
    install -Dm644 doomlauncher.cfg "${pkgdir}/etc/doomlauncher/doomlauncher.cfg"
    install -Dm644 doomlauncher_theme.rc "${pkgdir}/etc/doomlauncher/doomlauncher_theme.rc"

    # Install icon
    install -Dm644 doomlauncher.svg "${pkgdir}/usr/share/icons/hicolor/scalable/apps/doomlauncher.svg"

    # Install desktop entry
    install -Dm644 Doomlauncher.desktop "${pkgdir}/usr/share/applications/doomlauncher.desktop"
}

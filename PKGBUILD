# Maintainer: Zamhedonia <zamhedonia@gmx.de>
pkgname=doomlauncher
pkgver=1.0
pkgrel=1
pkgdesc="Simple terminal launcher for GZDoom with dialog UI"
arch=('any')
url="https://github.com/zamhedonia/doomlauncher"
license=('MIT')
depends=('dialog')
source=("${pkgname}-${pkgver}.tar.gz::https://github.com/zamhedonia/doomlauncher/archive/refs/tags/v${pkgver}.tar.gz")
sha256sums=('00d20277931c9492cb8b6f1dafa9a3739395416895ed26eb4d4173ecfc79d5a2')

package() {
    cd "${srcdir}/${pkgname}-${pkgver}"

    # Install main script
    install -Dm755 doomlauncher.sh "${pkgdir}/usr/bin/doomlauncher"

    # Install the LICENSE file
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"

    # Install config and theme
    install -Dm644 doomlauncher.cfg "${pkgdir}/etc/doomlauncher/doomlauncher.cfg"
    install -Dm644 doomlauncher_theme.rc "${pkgdir}/etc/doomlauncher/doomlauncher_theme.rc"
}

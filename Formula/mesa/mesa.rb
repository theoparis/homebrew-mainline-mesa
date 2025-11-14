class Mesa < Formula
  include Language::Python::Virtualenv
  desc "Bleeding-edge Mesa for macOS/aarch64 (mainline HEAD only)"
  homepage "https://gitlab.freedesktop.org/mesa/mesa"
  url "https://gitlab.freedesktop.org/mesa/mesa.git",
      branch: "main"
  license "MIT"

  url "https://gitlab.freedesktop.org/mesa/mesa/-/archive/07d059f3e20179266c12d5a59bde6a8249306bd2.gz"
  sha256 "a0021f6c95753569ff4780bfe90e8302fd1740459827e71d983eec9b98b46c80"
  version "main"

  patch do
    url "https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/38428.patch"
    sha256 "dbd7b6245718ed62296b459325f9b5bea56813a8086f85715dbfd3b3d72ae888"
  end

  pypi_packages package_name: "", extra_packages: %w[mako packaging ply pyyaml]

  resource "mako" do
    url "https://files.pythonhosted.org/packages/9e/38/bd5b78a920a64d708fe6bc8e0a2c075e1389d53bef8413725c63ba041535/mako-1.3.10.tar.gz"
    sha256 "99579a6f39583fa7e5630a28c3c1f440e4e97a414b80372649c0ce338da2ea28"
  end

  resource "markupsafe" do
    url "https://files.pythonhosted.org/packages/7e/99/7690b6d4034fffd95959cbe0c02de8deb3098cc577c67bb6a24fe5d7caa7/markupsafe-3.0.3.tar.gz"
    sha256 "722695808f4b6457b320fdc131280796bdceb04ab50fe1795cd540799ebe1698"
  end

  resource "packaging" do
    url "https://files.pythonhosted.org/packages/a1/d4/1fc4078c65507b51b96ca8f8c3ba19e6a61c8253c72794544580a7b6c24d/packaging-25.0.tar.gz"
    sha256 "d443872c98d677bf60f6a1f2f8c1cb748e8fe762d2bf9d3148b5599295b0fc4f"
  end

  resource "ply" do
    url "https://files.pythonhosted.org/packages/e5/69/882ee5c9d017149285cab114ebeab373308ef0f874fcdac9beb90e0ac4da/ply-3.11.tar.gz"
    sha256 "00c7c1aaa88358b9c765b6d3000c6eec0ba42abca5351b095321aef446081da3"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/05/8e/961c0007c59b8dd7729d542c61a4d537767a59645b82a0b521206e1e25c2/pyyaml-6.0.3.tar.gz"
    sha256 "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f"
  end

  def python3
    "python3.14"
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkgconf" => :build
  depends_on "python@3.14" => :build
  depends_on "cmake" => :build
  depends_on "spirv-tools" => :build
  depends_on "glslang" => :build
  depends_on "vulkan-profiles" => :build
  depends_on "vulkan-headers"
  depends_on "spirv-llvm-translator"
  depends_on "llvm"
  depends_on "libclc"
  depends_on "expat"
  depends_on "zstd"
  depends_on "libpng"
  depends_on "zlib-ng-compat"

  def install
    llvm = Formula["llvm"]
    vulkan = Formula["vulkan-headers"]

    venv = virtualenv_create(buildpath/"venv", python3)
    venv.pip_install resources.reject { |r| OS.mac? && r.name == "ply" }
    ENV.prepend_path "PYTHONPATH", venv.site_packages
    ENV.prepend_path "PATH", venv.root/"bin"

    # TODO: zink currently seems to require moltenvk where it shouldn't?
    # -Dgallium-drivers=zink
    args = %W[
      -Dplatforms=macos
      -Degl-native-platform=surfaceless
      -Dvulkan-drivers=swrast,kosmickrisp
      -Dopengl=true
      -Dgles1=false
      -Dgles2=true
      -Dzstd=enabled
      -Dllvm=enabled
      -Dmoltenvk-dir=#{vulkan.opt_prefix}
      -Dmicrosoft-clc=disabled
      -Dvalgrind=disabled
      -Dvulkan-layers=overlay,screenshot
      -Dvideo-codecs=all
      -Dglx=disabled
      -Dbuild-tests=false
      -Dbuildtype=release
      --prefix=#{prefix}
    ]

    system "meson", "setup", "build", *args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  def caveats
    <<~EOS
      Mesa mainline was installed into:
        #{prefix}

      You should export these paths when developing/testing:

        export DYLD_LIBRARY_PATH=#{opt_lib}:$DYLD_LIBRARY_PATH
        export LIBGL_DRIVERS_PATH=#{opt_lib}/dri
        export VK_DRIVER_FILES=#{opt_share}/vulkan/icd.d/kosmickrisp_mesa_icd.aarch64.json

      Zink will use KosmicKrisp automatically on macOS.
    EOS
  end
end


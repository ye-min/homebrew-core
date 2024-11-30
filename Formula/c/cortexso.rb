class Cortexso < Formula
  desc "Drop-in, local AI alternative to the OpenAI stack"
  homepage "https://cortex.so/"
  url "https://github.com/janhq/cortex.cpp/archive/refs/tags/v1.0.3.tar.gz"
  sha256 "dcf02f662ffc11a4925826db99d408d44f01db64bec3c888a9b9e05f3e747654"
  license "Apache-2.0"
  head "https://github.com/janhq/cortex.cpp.git", branch: "dev"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    rebuild 1
    sha256                               arm64_sequoia:  "c5b000f80754025ef2e26c62a74172b0b70dbde1217544f602d29e933f221b6e"
    sha256                               arm64_sonoma:   "5a40692000193b98c8274e0f4b6cd366558fc464e91fbc9222af2e16b4238b2b"
    sha256                               arm64_ventura:  "e505143e5417668b3027c83e923871bacbbaf5ac0a86bde0e0b156bfad7e0c36"
    sha256                               arm64_monterey: "0d30abe3e770dc4596348ba52c39bdeadbc270d61213a563c8f655c694858362"
    sha256                               sonoma:         "33d3271364280efa43bdf39ff61532e4e6f1ec5e1d0a2c3e9c70695cd6f5977f"
    sha256                               ventura:        "9dc575f5fcdb463e7fd8e00159329fe29080b76e3c563de647c90b2affaf9141"
    sha256                               monterey:       "30aa7c29ce75ef1429af1393073d4970a6b101bad2ddc638164e9b22cbb6b54e"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "f02d924016dcab7dce2faecaac5a77ba04ad4ba20dcac3e0fcc753d248364264"
  end

  depends_on "cmake" => :build
  depends_on "cli11" => :build
  depends_on "cpp-httplib" => :build
  depends_on "eventpp" => :build
  depends_on "indicators" => :build
  depends_on "tabulate" => :build

  depends_on "drogon"
  depends_on "jsoncpp"
  depends_on "libarchive"
  depends_on "minizip"
  depends_on "openssl@3"
  depends_on "sqlite"
  depends_on "sqlitecpp"
  depends_on "yaml-cpp"

  uses_from_macos "curl"

  conflicts_with "cortex", because: "both install `cortex` binaries"

  # No tags. For now, using same provided by vcpkg submodule
  resource "hwinfo" do
    url "https://github.com/lfreist/hwinfo/archive/46690dd36727b868c5bb7a7316bb2ee52a898349.tar.gz"
    sha256 "3fbee876de242f21b1f9db1949907d4a92b7952f903efaf45d9df500bd9c7a48"
  end

  def install
    resource("hwinfo").stage do
      system "cmake", "-S", ".", "-B", "build",
                      "-DBUILD_EXAMPLES=OFF",
                      "-DBUILD_TESTING=OFF",
                      "-DHWINFO_SHARED=OFF",
                      "-DHWINFO_STATIC=ON",
                      *std_cmake_args(install_prefix: buildpath/"hwinfo")
      system "cmake", "--build", "build"
      system "cmake", "--install", "build"
    end

    inreplace ["engine/CMakeLists.txt", "engine/cli/CMakeLists.txt"] do |s|
      # Do not statically link to OpenSSL library
      s.gsub! "set(OPENSSL_USE_STATIC_LIBS TRUE)", ""

      # Work around the usage of a vcpkg-specific CMake file
      s.gsub! "find_package(unofficial-minizip CONFIG REQUIRED)", <<~CMAKE
        find_library(MINIZIP_LIBRARY NAMES minizip REQUIRED)
        add_library(unofficial::minizip::minizip UNKNOWN IMPORTED)
        set_target_properties(unofficial::minizip::minizip PROPERTIES IMPORTED_LOCATION "${MINIZIP_LIBRARY}")
      CMAKE
    end

    # Set CMAKE_MODULE_PATH to avoid copy of FindSqlite3 in `drogon`
    args = %W[
      -DCMAKE_MODULE_PATH=#{Formula["cmake"].opt_pkgshare}/Modules
      -Dlfreist-hwinfo_DIR=#{buildpath}/hwinfo/lib/cmake/hwinfo
    ]

    system "cmake", "-S", "engine", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    # FIXME: There are no CMake installation rules
    bin.install "build/cortex", "build/cortex-server"
  end

  test do
    port = free_port
    system bin/"cortex", "start", "--port", port.to_s
    begin
      sleep 10
      assert_match "cortex-cpp is alive", shell_output("curl http://127.0.0.1:#{port}/healthz")
    ensure
      system bin/"cortex", "stop"
    end
  end
end

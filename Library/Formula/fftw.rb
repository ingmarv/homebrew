require 'formula'

class Fftw < Formula
  desc "C routines to compute the Discrete Fourier Transform"
  homepage 'http://www.fftw.org'
  url 'http://www.fftw.org/fftw-3.3.4.tar.gz'
  sha1 'fd508bac8ac13b3a46152c54b7ac885b69734262'
  revision 1

  bottle do
    cellar :any
    sha1 "b5c2d04489567aff02e2e002d906ce7349057f6e" => :yosemite
    sha1 "af376c8efd9de7501d56f763a1ead65a5d32e533" => :mavericks
    sha1 "1585929f22c6851d87cf9d451cd26ff403991a8c" => :mountain_lion
  end

  option "with-fortran", "Enable Fortran bindings"
  option :universal
  option "with-mpi", "Enable MPI parallel transforms"

  depends_on :fortran => :optional
  depends_on :mpi => [:cc, :optional]

  def install
    args = ["--enable-shared",
            "--disable-debug",
            "--prefix=#{prefix}",
            "--enable-threads",
            "--disable-dependency-tracking"]
    simd_args = ["--enable-sse2"]
    simd_args << "--enable-avx" if ENV.compiler == :clang and Hardware::CPU.avx? and !build.bottle?

    args << "--disable-fortran" if build.without? "fortran"
    args << "--enable-mpi" if build.with? "mpi"

    ENV.universal_binary if build.universal?

    # single precision
    # enable-sse2 and enable-avx works for both single and double precision
    system "./configure", "--enable-single", *(args + simd_args)
    system "make install"

    # clean up so we can compile the double precision variant
    system "make clean"

    # double precision
    # enable-sse2 and enable-avx works for both single and double precision
    system "./configure", *(args + simd_args)
    system "make install"

    # clean up so we can compile the long-double precision variant
    system "make clean"

    # long-double precision
    # no SIMD optimization available
    system "./configure", "--enable-long-double", *args
    system "make install"
  end

  test do
    # Adapted from the sample usage provided in the documentation:
    # http://www.fftw.org/fftw3_doc/Complex-One_002dDimensional-DFTs.html
    (testpath/'fftw.c').write <<-TEST_SCRIPT.undent
      #include <fftw3.h>

      int main(int argc, char* *argv)
      {
          fftw_complex *in, *out;
          fftw_plan p;
          long N = 1;
          in = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);
          out = (fftw_complex*) fftw_malloc(sizeof(fftw_complex) * N);
          p = fftw_plan_dft_1d(N, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
          fftw_execute(p); /* repeat as needed */
          fftw_destroy_plan(p);
          fftw_free(in); fftw_free(out);
          return 0;
      }
    TEST_SCRIPT

    system ENV.cc, '-o', 'fftw', 'fftw.c', '-lfftw3', *ENV.cflags.to_s.split
    system './fftw'
  end
end

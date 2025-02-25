# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{8..11} pypy3 )

inherit distutils-r1 multiprocessing

DESCRIPTION="Simple powerful testing with Python"
HOMEPAGE="
	https://pytest.org/
	https://github.com/pytest-dev/pytest/
	https://pypi.org/project/pytest/
"
SRC_URI="mirror://pypi/${PN:0:1}/${PN}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~loong ~m68k ~mips ~ppc ~ppc64 ~riscv ~s390 ~sparc ~x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-python/attrs-19.2.0[${PYTHON_USEDEP}]
	dev-python/iniconfig[${PYTHON_USEDEP}]
	>=dev-python/more-itertools-4.0.0[${PYTHON_USEDEP}]
	dev-python/packaging[${PYTHON_USEDEP}]
	>=dev-python/pluggy-0.12[${PYTHON_USEDEP}]
	>=dev-python/py-1.8.2[${PYTHON_USEDEP}]
	>=dev-python/tomli-1.0.0[${PYTHON_USEDEP}]
"
BDEPEND="
	>=dev-python/setuptools_scm-6.2.3[${PYTHON_USEDEP}]
	test? (
		${RDEPEND}
		$(python_gen_cond_dep '
			dev-python/argcomplete[${PYTHON_USEDEP}]
			>=dev-python/hypothesis-3.56[${PYTHON_USEDEP}]
			dev-python/mock[${PYTHON_USEDEP}]
			>=dev-python/pygments-2.7.2[${PYTHON_USEDEP}]
			dev-python/pytest-xdist[${PYTHON_USEDEP}]
			dev-python/requests[${PYTHON_USEDEP}]
			dev-python/xmlschema[${PYTHON_USEDEP}]
		' python3_{8..11} pypy3)
	)
"

PATCHES=(
	"${FILESDIR}/${P}-py311.patch"
)

src_test() {
	# workaround new readline defaults
	echo "set enable-bracketed-paste off" > "${T}"/inputrc || die
	local -x INPUTRC="${T}"/inputrc
	distutils-r1_src_test
}

python_test() {
	if ! has "${EPYTHON}" python3.{8..11} pypy3; then
		einfo "Skipping tests on ${EPYTHON}"
		return
	fi

	local -x PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
	local -x COLUMNS=80

	local EPYTEST_DESELECT=(
		# broken by epytest args
		testing/test_warnings.py::test_works_with_filterwarnings

		# tend to be broken by random pytest plugins
		# (these tests patch PYTEST_DISABLE_PLUGIN_AUTOLOAD out)
		testing/test_helpconfig.py::test_version_less_verbose
		testing/test_helpconfig.py::test_version_verbose
		testing/test_junitxml.py::test_random_report_log_xdist
		testing/test_junitxml.py::test_runs_twice_xdist
		testing/test_terminal.py::TestProgressOutputStyle::test_xdist_normal
		testing/test_terminal.py::TestProgressOutputStyle::test_xdist_normal_count
		testing/test_terminal.py::TestProgressOutputStyle::test_xdist_verbose
		testing/test_terminal.py::TestProgressWithTeardown::test_xdist_normal
		testing/test_terminal.py::TestTerminalFunctional::test_header_trailer_info
		testing/test_terminal.py::TestTerminalFunctional::test_no_header_trailer_info

		# unstable with xdist
		testing/test_terminal.py::TestTerminalFunctional::test_verbose_reporting_xdist
	)

	[[ ${EPYTHON} == pypy3 ]] && EPYTEST_DESELECT+=(
		# regressions on pypy3.9
		# https://github.com/pytest-dev/pytest/issues/9787
		testing/test_skipping.py::test_errors_in_xfail_skip_expressions
		testing/test_unraisableexception.py
	)

	epytest -p xdist -n "$(makeopts_jobs "${MAKEOPTS}" "$(get_nproc)")"
}

PORTNAME=       acme-orchestrate
DISTVERSION=    1.0.2
CATEGORIES=     security sysutils
MASTER_SITES=   
DISTFILES=

MAINTAINER=     admin@mrhelbig.com
COMMENT=        Local ACME certificate reconciliation and replica deployment
WWW=		https://github.com/misterhelbig/acme-orchestrate/

LICENSE=        BSD2CLAUSE
LICENSE_FILE=   ${.CURDIR}/LICENSE


RUN_DEPENDS=    acme.sh:security/acme.sh \
                rsync:net/rsync \
                nsupdate:dns/bind-tools

NO_BUILD=       yes
NO_ARCH=        yes

# Deliberately do not create acme accounts, modify cron or install secrets.
do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/sbin
	${INSTALL_SCRIPT} ${FILESDIR}/acme-orchestrate ${STAGEDIR}${PREFIX}/sbin/acme-orchestrate
	${INSTALL_SCRIPT} ${FILESDIR}/acme-orchestrate-push ${STAGEDIR}${PREFIX}/sbin/acme-orchestrate-push
	${INSTALL_SCRIPT} ${FILESDIR}/acme-orchestrate-runner ${STAGEDIR}${PREFIX}/sbin/acme-orchestrate-runner
	${MKDIR} ${STAGEDIR}${PREFIX}/share/acme-orchestrate
	${INSTALL_DATA} ${FILESDIR}/dns_nsupdate.sh ${STAGEDIR}${PREFIX}/share/acme-orchestrate/dns_nsupdate.sh
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/acme
	${INSTALL_DATA} ${FILESDIR}/domains.conf.sample ${STAGEDIR}${PREFIX}/etc/acme/domains.conf.sample
	${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${FILESDIR}/README.install ${STAGEDIR}${DOCSDIR}/README.install
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/newsyslog.conf.d
	${INSTALL_DATA} ${FILESDIR}/acme-orchestrate.newsyslog.conf.sample ${STAGEDIR}${PREFIX}/etc/newsyslog.conf.d/acme-orchestrate.conf.sample
	${INSTALL_DATA} ${FILESDIR}/orchestrate.conf.sample ${STAGEDIR}${PREFIX}/etc/acme/orchestrate.conf.sample

.include <bsd.port.mk>

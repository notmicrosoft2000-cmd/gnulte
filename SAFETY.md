# GNULTE Authorized Use and Safety Policy

GNULTE and GNULTE-SCAN are network testing, diagnostics, discovery,
research, and security-testing tools.

GNULTE contains capabilities that can perform ARP-based
man-in-the-middle operation, traffic manipulation, traffic
impairment, and packet capture.

GNULTE-SCAN can perform LAN device discovery and optional active
network reconnaissance.

These capabilities can affect network connectivity, network traffic,
and potentially sensitive information.

## AUTHORIZED USE ONLY

Use GNULTE and GNULTE-SCAN only on networks, devices, systems,
and communications that you own or are explicitly authorized to test.

Authorization should cover the specific systems and activities being
tested.

Permission to use a network does not automatically mean permission
to intercept, manipulate, capture, scan, or disrupt every system or
communication on that network.

## APPROPRIATE USE

Examples include:

* Testing a personally owned home laboratory.
* Testing personally owned devices.
* Testing a network where the owner has explicitly authorized the test.
* Authorized penetration testing.
* Security research in an isolated laboratory.
* Network resilience testing.
* Application behavior testing under simulated bad-network conditions.
* Educational exercises in a controlled environment.

## PROHIBITED UNAUTHORIZED USE

Do not use GNULTE or GNULTE-SCAN to:

* Intercept traffic without authorization.
* Manipulate traffic without authorization.
* Disrupt another person's network access.
* Deliberately degrade a third party's network service.
* Capture private communications without authorization.
* Scan systems without permission.
* Circumvent security controls without authorization.
* Attack third-party infrastructure.
* Use ARP spoofing against networks or devices that are outside the
  approved testing scope.

## PACKET CAPTURE

Packet captures can contain sensitive information.

Depending on the traffic, captures may contain:

* IP addresses
* DNS requests
* URLs
* application metadata
* authentication information
* session information
* personal communications
* other confidential network data

Only capture traffic when such capture is explicitly authorized.

Store packet captures securely.

Delete captures when they are no longer required.

## NETWORK IMPAIRMENT

GNULTE can intentionally introduce network conditions including:

* latency
* jitter
* packet loss
* packet duplication
* packet reordering
* bandwidth restrictions

These features can interrupt connectivity.

Only perform network impairment against systems within the approved
testing scope.

## SCOPE

Before beginning a test, the operator should know:

* Which network is being tested.
* Which systems are in scope.
* Which IP addresses are in scope.
* Which testing methods are authorized.
* When the test may occur.
* Which systems are excluded.

If an unexpected device or system is affected, stop the test.

## USER RESPONSIBILITY

The operator is responsible for obtaining appropriate authorization
and complying with applicable laws, regulations, policies, contracts,
and network-access rules.

The project authors do not grant permission to attack, intercept,
scan, disrupt, capture, or manipulate any third-party system.

The publication or distribution of GNULTE does not itself authorize
testing of any particular network.
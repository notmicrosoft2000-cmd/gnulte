# Authorized Testing Rules

Before using GNULTE or GNULTE-SCAN against a network that is not
personally owned by the operator, the operator should have explicit
authorization.

A good authorization record should identify:

```
1. Who authorized the test.
2. Which organization owns the systems.
3. Which network or systems are in scope.
4. Which IP addresses/ranges are in scope.
5. Which testing techniques are authorized.
6. The permitted testing dates/times.
7. Any excluded systems.
8. Whether packet capture is permitted.
9. Whether traffic disruption is permitted.
10. Who should be contacted if something goes wrong.
```

For example:

```
Authorized Tester:
    Example Security Team

Network Owner:
    Example Organization

Scope:
    192.168.1.0/24

Allowed:
    GNULTE-SCAN discovery
    Nmap reconnaissance
    Network impairment testing

Packet Capture:
    Authorized

Testing Window:
    2026-09-12 10:00-12:00

Excluded:
    192.168.1.1
    Production servers
```

The exact legal requirements for authorization depend on the
jurisdiction and circumstances.
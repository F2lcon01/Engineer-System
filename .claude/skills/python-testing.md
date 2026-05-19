---
name: python-testing
description: Python testing patterns with pytest. Loaded when writing test_*.py or *_test.py files or when the project uses pytest. Provides fixtures, parametrize, mocking with monkeypatch/unittest.mock, and CI integration patterns.
---

# Python Testing Skill

Activates when writing or modifying Python test files. Read **before** writing any test.

## The Three Laws

1. **One assertion per intent** — many `assert` lines OK; many concepts in one test NOT OK
2. **Fixtures over `setUp`** — pytest fixtures compose, inherit, and parametrize cleanly
3. **No `print()` for debugging** — use `pytest -s` + the debugger, or just delete it

## Minimum viable test

```python
# test_cart.py
import pytest
from cart import calculate_total, NegativePriceError


def test_empty_cart_returns_zero():
    assert calculate_total([]) == 0


def test_sums_prices_with_tax():
    items = [{"price": 100}, {"price": 50}]
    assert calculate_total(items, tax_rate=0.1) == 165


def test_rejects_negative_price():
    with pytest.raises(NegativePriceError, match="negative"):
        calculate_total([{"price": -1}])
```

## Fixtures

```python
@pytest.fixture
def sample_user():
    return {"id": 42, "email": "test@example.com"}


@pytest.fixture
def db_session(tmp_path):
    """Real SQLite in tmp dir — no shared state across tests."""
    import sqlite3
    db = sqlite3.connect(tmp_path / "test.db")
    db.execute("CREATE TABLE users (id INT, email TEXT)")
    yield db
    db.close()


def test_insert_user(db_session, sample_user):
    db_session.execute("INSERT INTO users VALUES (?, ?)",
                        (sample_user["id"], sample_user["email"]))
    db_session.commit()
    rows = db_session.execute("SELECT * FROM users").fetchall()
    assert len(rows) == 1
```

### Fixture scope (use sparingly — broader scope = harder isolation)

| Scope | When |
|-------|------|
| `function` (default) | Stateful resources — DB sessions, temp dirs |
| `class` | Shared setup across one TestClass |
| `module` | Expensive read-only setup, e.g. parsed config |
| `session` | One-time global setup, e.g. a Docker container |

## Parametrize (table-driven tests)

```python
@pytest.mark.parametrize("amount,tax,expected", [
    (100, 0.0, 100),
    (100, 0.1, 110),
    (0, 0.5, 0),
    (-1, 0.0, pytest.raises(NegativePriceError)),
])
def test_calculate(amount, tax, expected):
    if isinstance(expected, type) and issubclass(expected, Exception):
        with pytest.raises(expected):
            calculate_total([{"price": amount}], tax)
    else:
        assert calculate_total([{"price": amount}], tax) == expected
```

## Mocking patterns

### monkeypatch (built-in, pytest-native)

```python
def test_uses_mocked_env(monkeypatch):
    monkeypatch.setenv("API_KEY", "fake-key")
    from app import get_api_key
    assert get_api_key() == "fake-key"
```

### unittest.mock for callables

```python
from unittest.mock import patch, MagicMock

def test_fetches_user():
    with patch("app.requests.get") as mock_get:
        mock_get.return_value = MagicMock(
            status_code=200,
            json=lambda: {"id": 1}
        )
        from app import fetch_user
        assert fetch_user(1) == {"id": 1}
        mock_get.assert_called_once_with("https://api/users/1", timeout=5)
```

### Mock that raises

```python
def test_handles_network_error():
    with patch("app.requests.get", side_effect=ConnectionError("down")):
        result = fetch_user_safe(1)
        assert result is None
```

## Async tests (pytest-asyncio)

```python
import pytest

@pytest.mark.asyncio
async def test_async_fetch():
    user = await fetch_user_async(1)
    assert user["id"] == 1
```

Requires: `pip install pytest-asyncio` and `asyncio_mode = "auto"` in `pyproject.toml`.

## Coverage requirements

For every public function:

| Test type | Required? | Why |
|-----------|-----------|-----|
| Happy path | Yes | Baseline |
| At least one failure (raises) | **Yes** | Half the contract |
| Edge case (empty, None, 0, max) | Yes | Bugs hide in edges |
| Type validation if pydantic/dataclass | Yes | Verify rejection works |

## Forbidden patterns

| Pattern | Why |
|---------|-----|
| `assert some_value` (bare truthy) | Hides actual value on failure — use exact match |
| `time.sleep(1)` to wait for async | Use `pytest.wait_for` or proper async patterns |
| `try: ... except: pass` in tests | Silent failure |
| `if __name__ == '__main__': test_x()` | Pytest discovers tests itself — delete |
| Real network calls | Use `responses`, `httpx_mock`, or `monkeypatch` |
| `@pytest.mark.skip` left committed | Either fix or delete |

## pyproject.toml minimum

```toml
[tool.pytest.ini_options]
minversion = "8.0"
testpaths = ["tests"]
addopts = [
    "-ra",                  # show short summary for all except passed
    "--strict-markers",     # fail on undeclared markers
    "--strict-config",      # fail on unknown config keys
]

[tool.coverage.run]
branch = true
source = ["src"]
```

## CI command

```bash
pytest --cov=src --cov-report=term-missing --cov-fail-under=80
```

Exits non-zero if coverage drops below 80%.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Tests pass alone, fail in CI | Likely test order dependency — use `pytest-randomly` to expose |
| `assert mock_x.called` instead of `assert_called_once_with(...)` | The first only checks "any call"; the second checks correctness |
| Mocking `app.dependency` when test imports `app` | Mock where it's looked up, not where it's defined |
| Huge `conftest.py` with 30 fixtures | Split per test file — `conftest.py` is for cross-cutting only |

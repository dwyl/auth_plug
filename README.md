<div align="center">

# `auth_plug`

The Elixir Plug that _seamlessly_ handles
all your authentication/authorization needs.

[![Build Status](https://img.shields.io/travis/dwyl/auth_plug/master.svg?style=flat-square)](https://travis-ci.org/dwyl/auth_plug)
[![codecov.io](https://img.shields.io/codecov/c/github/dwyl/auth_plug/master.svg?style=flat-square)](http://codecov.io/github/dwyl/auth_plug?branch=master)
[![Hex.pm](https://img.shields.io/hexpm/v/auth_plug?color=brightgreen&style=flat-square)](https://hex.pm/packages/auth_plug)
[![Libraries.io dependency status](https://img.shields.io/librariesio/release/hex/auth_plug?logoColor=brightgreen&style=flat-square)](https://github.com/dwyl/auth_plug/blob/master/mix.exs)
[![HitCount](http://hits.dwyl.com/dwyl/auth_plug.svg)](http://hits.dwyl.com/dwyl/auth_plug)
</div>
<br />

## Why? 🤷

<!--
You want a way to add authentication
to your Elixir/Phoenix App
in the fewest steps and least code.
We did too. So we built `auth_plug`.
-->

***Frustrated*** by the **complexity**
and **incomplete docs/tests**
in **_existing_ auth solutions**,
we built **`auth_plug`** to **simplify** our lives.
We needed a way to ***minimise***
the number of steps
and amount of boilerplate **code** required
to add auth in our app(s).
**`auth_plug`** allows us to **setup**
auth in any Elixir/Phoenix
App in **_less_ than 2 minutes**
and only **7 lines** of code.

<!-- revisit or remove this section
### Pain 😧

We try to maintain a
["beginner's mind"](https://en.wikipedia.org/wiki/Shoshin)
in everything we do.

There are virtually infinite options
for 3rd party Authentication.
Most are complex and unfriendly to beginners.
They require understanding the difference
between an authentication scheme, strategy or implementation.
We have used everything from
[black box](https://en.wikipedia.org/wiki/Black_box)
(closed source)
services that promise the world but are consistently
painful to setup, to open source projects that
are woefully undocumented and lack automated tests
so we cannot _rely_ on them.
We got tired of compromising on the UX of auth,
so we built _exactly_ what we wanted
as the "users" of our own product.

-->

## What? 🔐

A plug
a _complete_ beginner can use to add auth to a
Phoenix App
and _understand_ how it works.
No macros/behaviours to `use` (_confuse_).
No complex configuration.
No genservers or extra OTP apps.
Just a basic plug that uses Phoenix Sessions
and standards-based JSON Web Tokens (JWT).
Refreshingly simple. The way auth _should_ be done.

## Who? 👥

We built this plug for use in our products/services.
It does _exactly_ what we want it to and nothing more.
It's tested, documented and open source the way _all_ our code is.
It's **not _yet_** a **general purpose** auth solution
that _anyone_ can use.
If after reading through this you feel that
this is something you would like to have
in your own Elixir/Phoenix project,
let us know!


## How? 💡

### 1. Installation 📝

Add **`auth_plug`**
to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:auth_plug, "~> 0.8.0"}
  ]
end
```
Once you've saved the `mix.exs` file,
download the dependency with:

```sh
mix deps.get
```

### 2. Get Your `AUTH_API_KEY` 🔑

Visit: https://dwylauth.herokuapp.com/profile/apikeys/new
And create your `AUTH_API_KEY`.
e.g:
![new-api-key-form](https://user-images.githubusercontent.com/194400/80422785-b76d6480-88d6-11ea-9fbb-4acbc969aeac.png)

![new-api-key](https://user-images.githubusercontent.com/194400/80422804-be947280-88d6-11ea-920e-17e810816f17.png)

#### 2.1 Save it as an Environment Variable

Create a file called `.env` in the root directory of your app
and add the following line:

```txt
export AUTH_API_KEY=2cfxNaWUwJBq1F4nPndoEHZJ5YCCNqXbJ6GaSXj6BPNTjMSc4EV/2cfxNadrhMZk3iaT1L5k6Wt67c9ScbGNPz8BwLH1qvpDNAARQ9J
```

The run the following command in your terminal:
```
source .env
```
That will export the environment variable AUTH_API_KEY.


Remember to add `.env` to your [`.gitignore`](https://github.com/dwyl/auth_plug/blob/1ebb60938487da7e740a79b2a4639b29f2ba44ac/.gitignore#L52) file.
e.g:
```
echo ".env" >> .gitignore
```


### 3. Protect a Route





## Documentation

Documentation can be found at
[https://hexdocs.pm/auth_plug](https://hexdocs.pm/auth_plug).

If _anything_ is unclear,
please open an issue:
https://github.com/dwyl/auth_plug/issues



## Recommended / Relevant Reading

If you are new to Elixir Plug,
we recommend following:
[github.com/dwyl/elixir-plug-tutorial](https://github.com/dwyl/elixir-plug-tutorial).

To understand JSON Web Tokens,
read:
[https://github.com/dwyl/learn-json-web-tokens](https://github.com/dwyl/learn-json-web-tokens).

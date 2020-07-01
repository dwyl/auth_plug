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
we built **`auth_plug`** to **simplify** our lives. <br />

We needed a way to ***minimise***
the steps
and **code** required
to add auth to our app(s).
With **`auth_plug`** we can **setup**
auth in any Elixir/Phoenix
App in **_less_ than 2 minutes**
with only **5 lines** of config/code
and **_one_ environment variable**.

![true](https://user-images.githubusercontent.com/194400/80473192-b1f73500-893d-11ea-87c1-edf4fec53da2.jpg)




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

An Elixir Plug (_HTTP Middleware_)
that a _complete_ beginner can use to add auth to a
Phoenix App
and _understand_ how it works. <br />
No macros/behaviours to `use` (_confuse_).
No complex configuration or "implementation".
Just a basic plug that uses Phoenix Sessions
and standards-based JSON Web Tokens (JWT).
Refreshingly simple. The way auth _should_ be done.

<div align="center">
  <a href="https://travis-ci.com/">
    <img src="https://user-images.githubusercontent.com/194400/80484054-0060ff80-894f-11ea-80fc-537c1a9779a6.png" alt="auth_plug diagram" width="800">
  </a>

Edit this diagram:
[docs.google.com/presentation/d/1PUKzbRQOEgHaOmaEheU7T3AHQhRT8mhGuqVKotEJkM0](https://docs.google.com/presentation/d/1PUKzbRQOEgHaOmaEheU7T3AHQhRT8mhGuqVKotEJkM0/edit#slide=id.g841dc8bc44_0_5)

</div>

**`auth_plug`** protects any routes in your app
that require authentication. <br />

**`auth_plug`** is just
[57 lines](https://codecov.io/gh/dwyl/auth_plug/tree/master/lib)
of (_significant_)
[code](https://github.com/dwyl/auth_plug/tree/master/lib);
the rest is comprehensive comments
to help _everyone understand_ how it works.
As with _all_ our code,
it's meant to be as beginner-friendly as possible.
If you get stuck or have any questions,
please [***ask***!](https://github.com/dwyl/auth_plug/issues)



## Who? 👥

We built this plug for use in _our_ products/services.
It does _exactly_ what we want it to and nothing more.
It's tested, documented and open source the way _all_ our code is.
It's **not _yet_** a **general purpose** auth solution
that _anyone_ can use.
If after reading through this you feel that
this is something you would like to have
in your own Elixir/Phoenix project,
[***tell us***!](https://github.com/dwyl/auth_plug/issues)


# How? 💡



_Before_ you attempt to use the **`auth_plug`**,
try the Heroku example version so you know what to expect: <br />
https://auth-plug-example.herokuapp.com/admin

![auth_plug_example](https://user-images.githubusercontent.com/194400/80765920-154eb600-8b3c-11ea-90d4-a64224d31a5b.png)

Notice how when you first visit the
[`auth-plug-example.herokuapp.com/admin`](https://auth-plug-example.herokuapp.com/admin)
page, your browser is _redirected_ to:
https://dwylauth.herokuapp.com/?referer=https://auth-plug-example.herokuapp.com/admin&auth_client_id=etc.
The the auth service handles the actual authentication
and then transparently redirects back to
[`auth-plug-example.herokuapp.com/admin?jwt=etc.`](https://auth-plug-example.herokuapp.com/admin)
with a JWT session.

For more detail on how the `Auth` service works,
please see: https://github.com/dwyl/auth



If you get stuck during setup,
clone and run our fully working example:
https://github.com/dwyl/auth_plug_example#how

<br />

## 1. Installation 📝

Add **`auth_plug`**
to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:auth_plug, "~> 1.1.0"}
  ]
end
```
Once you've saved the `mix.exs` file,
download the dependency with:

```sh
mix deps.get
```

<br />

## 2. Get Your `AUTH_API_KEY` 🔑

Visit: https://dwylauth.herokuapp.com/settings/apikeys/new
And create your `AUTH_API_KEY`.
e.g:

![auth_plug_example_setup](https://user-images.githubusercontent.com/194400/80759455-3eb51500-8b2f-11ea-98fe-6e5154bfb349.gif)

### 2.1 Save it as an Environment Variable

Create a file called `.env` in the root directory of your app
and add the following line:

```txt
export AUTH_API_KEY=2cfxNaWUwJBq1F4nPndoEHZJ5YCCNqXbJ6Ga/2cfxNadrhMZk3iaT1L5k6Wt67c9ScbGNPz8BwLH1
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

<br />

## 3. Add `AuthPlug` to Your `router.ex` file to Protect a Route 🔒

Open the `lib/app_web/router.ex` file and locate the section:

```elixir
  scope "/", AppWeb do
    pipe_through :browser

    get "/", PageController, :index
  end
```

Immediately below this add the following lines of code:

```elixir
  pipeline :auth, do: plug(AuthPlug, %{auth_url: "https://dwylauth.herokuapp.com"})

  scope "/", AppWeb do
    pipe_through :browser
    pipe_through :auth
    get "/admin", PageController, :admin
  end
```

> E.g:
[`/lib/app_web/router.ex#L23-L29`](https://github.com/dwyl/auth_plug_example/blob/8ce0f10e656b94a93b8f02af240b3897ce23c006/lib/app_web/router.ex#L23-L29)


#### _Explanation_

There are two parts to this code:

1. Create a new pipeline called `:auth` which will execute the `AuthPlug`
passing in the `auth_url` as an initialisation option.
2. Create a new scope where we `pipe_through`
both the `:browser` and `:auth` pipelines.

This means that the `"/admin"` route is protected by `AuthPlug`.

> **Note**: Ensure the route you are protecting works _without_ `AuthPlug`.
If in doubt simply comment out the line `pipe_through :auth` to check.

<br />

## 4. Attempt to view the protected route to test the authentication! 👩‍💻

Now that the `/admin` route is protected by **`auth_plug`**,
attempt to view it in your browser e.g: http://localhost:4000/admin

If you are not already authenticated,
your browser will be redirected to:
https://dwylauth.herokuapp.com/?referer=http://localhost:4000/admin&auth_client_id=etc

Once you have successfully authenticated with your GitHub or Google account,
you will be redirected back to `localhost:4000/admin`
where the `/admin` route will be visible.

![admin-route](https://user-images.githubusercontent.com/194400/80760439-d23b1580-8b30-11ea-8941-160ece8a4a5f.png)

<br />

## That's it!! 🎉

You just setup auth in a Phoenix app using **`auth_plug`**!

If you got stuck or have any questions,
please
[open an issue](https://github.com/dwyl/auth_plug/issues),
we are here to help!


<br />

## Documentation

Documentation can be found at
[https://hexdocs.pm/auth_plug](https://hexdocs.pm/auth_plug). <br />
All our code is commented,
but if _anything_ is unclear,
please open an issue:
https://github.com/dwyl/auth_plug/issues

### Availiable infomation
By default using the dwylauth.herokuapp.com authentication service,
`auth_plug` makes the following infomation availiable in `conn.assigns`:

```
jwt :: string()
person :: %{
  auth_provider :: string()
  email :: string()
  givenName :: string()
  id :: integer()
  picture :: string()
  
  # Also includes standard jwt metadata you may find useful:
  aud, exp, iat, iss
}
```


## Recommended / Relevant Reading

If you are new to Elixir Plug,
we recommend following:
[github.com/dwyl/elixir-plug-tutorial](https://github.com/dwyl/elixir-plug-tutorial).

To understand JSON Web Tokens,
read:
[https://github.com/dwyl/learn-json-web-tokens](https://github.com/dwyl/learn-json-web-tokens).

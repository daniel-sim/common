//= require_tree .

function disableLoginSubmit(text = "Install") {
  var form = document.getElementById("login-form")
  var submit = document.getElementById("login-form__submit")
  submit.disabled = true
  submit.classList.add("disabled")
  submit.innerText = text
}

function maybeEnableLoginSubmit() {
  var submit = document.getElementById("login-form__submit")
  var shop = document.getElementById("shop")

  submit.innerText = "Install"
  if (shop.value !== "") {
    submit.disabled = false
    submit.classList.remove("disabled")
  }
}

function hidePromoCodeMessage() {
  var element = document.getElementById("login-form__promo-code-info")

  element.className = "hidden"
}

function setPromoCodeMessage(text, className) {
  var element = document.getElementById("login-form__promo-code-info")

  element.innerHTML = text
  element.className = className
}

function checkPromoCode(code) {
  if (code === "") {
    maybeEnableLoginSubmit()
    hidePromoCodeMessage()
    return
  }

  var xhr = new XMLHttpRequest()
  xhr.onreadystatechange = function() {
    if (xhr.readyState == XMLHttpRequest.DONE) {
      if (xhr.status !== 200) {
        setPromoCodeMessage('Could not check promo code; <a href="mailto:help@pluginuseful.com">contact us</a>.', "failed")
      } else {
        var json = JSON.parse(xhr.responseText)

        if (json["status"] === "error") {
          setPromoCodeMessage(json["message"], "failed")
        } else if (json["status"] === "valid") {
          setPromoCodeMessage(json["message"], "succeeded")
        } else {
          setPromoCodeMessage('Could not check promo code; <a href="mailto:help@pluginuseful.com">contact us</a>.', "failed")
        }
      }

      maybeEnableLoginSubmit()
    }
  }
  xhr.open("GET", "/promo_codes/check/" + code, true)
  xhr.send(null)
}

function handlePromoCodeChanged(event) {
  checkPromoCode(event.target.value)
}

document.addEventListener("DOMContentLoaded", function(event) {
  var loginForm = document.getElementById("login-form")
  var shop = document.getElementById("shop")
  var promoCode = document.getElementById("promo_code")

  if (!loginForm) return
  if (shop.value === "") disableLoginSubmit()

  if (promoCode.value !== "") checkPromoCode(promoCode.value)

  shop.addEventListener("input", function(event) {
    if (event.target.value === "") { return disableLoginSubmit() }
    maybeEnableLoginSubmit()
  })

  promoCode.addEventListener("input", function(event) {
    event.target.value = event.target.value.toUpperCase()
    disableLoginSubmit("Checking…")
  })
  promoCode.addEventListener("input", _.debounce(handlePromoCodeChanged, 400))
})

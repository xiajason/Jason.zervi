var captcha;
function generate() {
	// Clear old input
	document.getElementById("captchaValue").value = "";
	// Access the element to store
	// the generated captcha
	captcha = document.getElementById("image");
	var uniquechar = "";
	const randomchar ="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

	// Generate captcha for length of
	// 5 with random character
	for (let i = 1; i < 6; i++) {
		uniquechar += randomchar.charAt(
			Math.random() * randomchar.length)
	}
	// Store generated input
	captcha.innerHTML = uniquechar;
}



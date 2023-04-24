// Define canvas element and context
var canvas = document.createElement('canvas');
var ctx = canvas.getContext('2d');

// Set canvas size to fill the screen
canvas.width = window.innerWidth;
canvas.height = window.innerHeight;

// Add canvas to the page
document.getElementById('canvas-container').appendChild(canvas);

// Define word to animate
var word = 'PHP SandBox';
var fontSize = 120;
var fontFamily = 'Arial';
var textWidth = ctx.measureText(word).width;

// Define particle animation variables
var particleRadius = 2;
var particleCount = 500;
var particles = [];

// Define mouse variables
var mouseX = canvas.width / 2;
var mouseY = canvas.height / 2;

function cardClicked(card) {
    card.classList.add('card-clicked');
    setTimeout(() => {
        card.classList.remove('card-clicked');
    }, 200);
}

function toggleDarkMode() {
    const body = document.querySelector('body');
    body.classList.toggle('dark-mode');
}
// Define animation loop
function animate() {
    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw word
    ctx.font = fontSize + 'px ' + fontFamily;
    ctx.fillStyle = 'white';
    ctx.fillText(word, canvas.width / 2 - textWidth / 2, canvas.height / 2 + fontSize / 2);

    // Update particle positions
    particles.forEach(function (particle) {
        particle.x += particle.vx;
        particle.y += particle.vy;

        // Check if particle is off screen
        if (particle.x < 0 || particle.x > canvas.width || particle.y < 0 || particle.y > canvas.height) {
            // Reset particle position and velocity
            particle.x = canvas.width * Math.random();
            particle.y = -10;
            particle.vx = (Math.random() - 0.5) * 5;
            particle.vy = Math.random() * 2;
        }

        // Draw particle
        ctx.beginPath();
        ctx.arc(particle.x, particle.y, particleRadius, 0, 2 * Math.PI, false);
        ctx.fillStyle = 'white';
        ctx.fill();
    });

    // Calculate distance from mouse to word
    var distance = Math.sqrt(Math.pow(mouseX - canvas.width / 2, 2) + Math.pow(mouseY - canvas.height / 2, 2));

    // If mouse is close enough to word, check for fast movement
    if (distance < 100) {
        canvas.style.cursor = 'pointer';
        canvas.onclick = function () {
            // Clear canvas and start particle animation
            ctx.clearRect(0, 0, canvas.width, canvas.height);
            particles = [];
            for (var i = 0; i < particleCount; i++) {
                particles.push({
                    x: canvas.width * Math.random(),
                    y: canvas.height * Math.random(),
                    vx: (Math.random() - 0.5) * 5,
                    vy: Math.random() * 2
                });
            }

            // Display popup message
            alert('Welcome to the PHP Sandbox!');
        }
    } else {
        canvas.style.cursor = 'default';
        canvas.onclick = null;
    }

    // Request next animation frame
    requestAnimationFrame(animate);
}

// Initialize particle positions
for (var i = 0; i < particleCount; i++) {
    particles.push({
        x: canvas.width * Math.random(),
        y: canvas.height * Math.random(),
        vx: (Math.random() - 0.5) * 5,
        vy: Math.random() * 2
    });
}

// Add mousemove event listener to update mouse position
document.addEventListener('mousemove', function (event) {
    mouseX = event.clientX;
    mouseY = event.clientY;
});

// Start animation loop
requestAnimationFrame(animate);
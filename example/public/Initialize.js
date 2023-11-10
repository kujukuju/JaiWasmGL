window.addEventListener('load', () => {
    Jai.initialize(document.getElementById('canvas'), '/wasm32.wasm', exported);
});

const exported = {
    simple_function: () => {
        console.log('Called simple function.');
    },
    callback_function: (a, b) => {
        console.log('Callback ', a, b);
    },
};

const initialized = () => {
    Renderer.initialize();
    Loop.loop();
};

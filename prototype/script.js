const COLORS = [
    { name: 'Red', hex: '#ff3b30' },
    { name: 'Green', hex: '#4cd964' },
    { name: 'Orange', hex: '#ff9500' },
    { name: 'Blue', hex: '#007aff' },
    { name: 'Yellow', hex: '#ffcc00' },
    { name: 'Purple', hex: '#af52de' },
    { name: 'Cyan', hex: '#5ac8fa' }
];

let state = {
    secretCode: [],
    attempts: [], // Each attempt is { guess: [], feedback: [] }
    currentGuess: [null, null, null, null],
    activeIndex: 0,
    mode: 'advanced', // 'beginner' (line) or 'advanced' (dots)
    isGameOver: false,
    level: 1
};

const dom = {
    grid: document.getElementById('grid'),
    activeColors: document.getElementById('active-colors'),
    inputSlots: document.querySelectorAll('.input-slot'),
    knob: document.getElementById('knob'),
    levelNum: document.getElementById('level-num'),
    message: document.getElementById('message'),
    newGameBtn: document.getElementById('new-game'),
    beginnerBtn: document.getElementById('beginner-mode'),
    advancedBtn: document.getElementById('advanced-mode'),
    secretDisplay: document.getElementById('secret-display'),
    colorPicker: document.getElementById('color-picker'),
    colorOptions: document.getElementById('color-options')
};

function initGame() {
    state.secretCode = generateSecret();
    state.attempts = [];
    state.currentGuess = [null, null, null, null];
    state.activeIndex = 0;
    state.isGameOver = false;
    
    // Show secret in debug
    dom.secretDisplay.textContent = state.secretCode.map(i => COLORS[i].name).join(', ');
    
    renderBoard();
    renderInput();
    updateStatus("READY");
}

function generateSecret() {
    let indices = [0, 1, 2, 3, 4, 5, 6];
    let secret = [];
    for (let i = 0; i < 4; i++) {
        const randomIndex = Math.floor(Math.random() * indices.length);
        secret.push(indices.splice(randomIndex, 1)[0]);
    }
    return secret;
}

function renderBoard() {
    dom.grid.innerHTML = '';
    
    for (let r = 0; r < 7; r++) {
        const row = document.createElement('div');
        row.className = 'row';
        const attempt = state.attempts[r];

        const slotsContainer = document.createElement('div');
        slotsContainer.className = 'slots-container';

        for (let c = 0; c < 4; c++) {
            const slot = document.createElement('div');
            slot.className = 'slot';
            if (attempt) {
                const colorIndex = attempt.guess[c];
                slot.style.backgroundColor = COLORS[colorIndex].hex;
                slot.classList.add('filled');

                if (state.mode === 'beginner') {
                    const line = document.createElement('div');
                    line.className = 'line-indicator';
                    const feedbackMsg = attempt.feedback[c];
                    if (feedbackMsg === 'correct') line.style.backgroundColor = 'var(--color-green)';
                    else if (feedbackMsg === 'misplaced') line.style.backgroundColor = 'var(--color-white)';
                    else line.style.backgroundColor = 'var(--color-black)';
                    slot.appendChild(line);
                }
            }
            slotsContainer.appendChild(slot);
        }
        row.appendChild(slotsContainer);

        const feedbackContainer = document.createElement('div');
        feedbackContainer.className = 'feedback-container';
        
        let dots = [];
        if (attempt) {
            if (state.mode === 'beginner') {
                const correct = attempt.feedback.filter(f => f === 'correct').length;
                const misplaced = attempt.feedback.filter(f => f === 'misplaced').length;
                for (let i = 0; i < correct; i++) dots.push('correct');
                for (let i = 0; i < misplaced; i++) dots.push('misplaced');
                while (dots.length < 4) dots.push('wrong');
            } else {
                dots = attempt.feedback;
            }
        } else {
            dots = ['wrong', 'wrong', 'wrong', 'wrong'];
        }

        dots.forEach(type => {
            const dot = document.createElement('div');
            dot.className = 'dot-hint';
            if (attempt) {
                if (type === 'correct') {
                    dot.style.backgroundColor = 'var(--color-green)';
                    dot.style.borderColor = 'var(--color-green)';
                    dot.style.boxShadow = '0 0 5px var(--color-green)';
                } else if (type === 'misplaced') {
                    dot.style.backgroundColor = 'var(--color-white)';
                    dot.style.borderColor = 'var(--color-white)';
                    dot.style.boxShadow = '0 0 5px var(--color-white)';
                }
            }
            feedbackContainer.appendChild(dot);
        });
        
        row.appendChild(feedbackContainer);
        dom.grid.appendChild(row);
    }

    dom.activeColors.innerHTML = '';
    COLORS.forEach(c => {
        const dot = document.createElement('div');
        dot.className = 'range-color';
        dot.style.backgroundColor = c.hex;
        dom.activeColors.appendChild(dot);
    });
}

function renderInput() {
    dom.inputSlots.forEach((slot, i) => {
        slot.classList.toggle('active', i === state.activeIndex);
        const colorIdx = state.currentGuess[i];
        slot.style.backgroundColor = colorIdx !== null ? COLORS[colorIdx].hex : '#222';
    });
}

function updateStatus(msg) {
    dom.message.textContent = msg;
    dom.levelNum.textContent = String(state.level).padStart(3, '0');
}

function submitGuess() {
    if (state.isGameOver) return;
    if (state.currentGuess.some(c => c === null)) {
        updateStatus("FILL ALL SLOTS");
        return;
    }
    
    const unique = new Set(state.currentGuess);
    if (unique.size < 4) {
        updateStatus("USE UNIQUE COLORS");
        return;
    }

    const feedback = calculateFeedback(state.currentGuess, state.secretCode);
    state.attempts.push({
        guess: [...state.currentGuess],
        feedback: feedback
    });

    if (feedback.every(f => (state.mode === 'advanced' ? f === 'correct' : true)) && 
        (state.mode === 'advanced' ? feedback.filter(f=>f==='correct').length === 4 : state.currentGuess.every((c,i) => c === state.secretCode[i]))) {
        state.isGameOver = true;
        updateStatus("UNLOCKED!");
    } else if (state.attempts.length >= 7) {
        state.isGameOver = true;
        updateStatus("LOCKED! FAILED");
    } else {
        updateStatus("TRY AGAIN");
    }

    renderBoard();
}

function calculateFeedback(guess, secret) {
    if (state.mode === 'beginner') {
        return guess.map((color, i) => {
            if (color === secret[i]) return 'correct';
            if (secret.includes(color)) return 'misplaced';
            return 'wrong';
        });
    } else {
        let correct = 0;
        let misplaced = 0;
        let secretCopy = [...secret];
        let guessCopy = [...guess];
        for (let i = 0; i < 4; i++) {
            if (guessCopy[i] === secretCopy[i]) {
                correct++;
                secretCopy[i] = null;
                guessCopy[i] = null;
            }
        }
        for (let i = 0; i < 4; i++) {
            if (guessCopy[i] !== null) {
                let foundIdx = secretCopy.indexOf(guessCopy[i]);
                if (foundIdx !== -1) {
                    misplaced++;
                    secretCopy[foundIdx] = null;
                }
            }
        }
        let result = [];
        for (let i = 0; i < correct; i++) result.push('correct');
        for (let i = 0; i < misplaced; i++) result.push('misplaced');
        while (result.length < 4) result.push('wrong');
        return result;
    }
}

dom.knob.addEventListener('click', (e) => {
    submitGuess();
});

function showColorPicker(slotIndex) {
    if (state.isGameOver) return;
    state.activeIndex = slotIndex;
    renderInput();
    
    dom.colorOptions.innerHTML = '';
    COLORS.forEach((color, index) => {
        const option = document.createElement('div');
        option.className = 'color-option';
        option.style.backgroundColor = color.hex;
        option.onclick = () => {
            selectColor(index);
        };
        dom.colorOptions.appendChild(option);
    });
    
    dom.colorPicker.classList.remove('hidden');
}

function selectColor(colorIndex) {
    state.currentGuess[state.activeIndex] = colorIndex;
    dom.colorPicker.classList.add('hidden');
    renderInput();
}

document.addEventListener('click', (e) => {
    if (!dom.colorPicker.contains(e.target) && !Array.from(dom.inputSlots).some(s => s.contains(e.target))) {
        dom.colorPicker.classList.add('hidden');
    }
});

dom.inputSlots.forEach((slot, i) => {
    slot.addEventListener('click', (e) => {
        e.stopPropagation();
        showColorPicker(i);
    });
});

dom.newGameBtn.addEventListener('click', () => {
    state.level++;
    initGame();
});

dom.beginnerBtn.addEventListener('click', () => {
    state.mode = 'beginner';
    dom.beginnerBtn.classList.add('active');
    dom.advancedBtn.classList.remove('active');
    initGame();
});

dom.advancedBtn.addEventListener('click', () => {
    state.mode = 'advanced';
    dom.advancedBtn.classList.add('active');
    dom.beginnerBtn.classList.remove('active');
    initGame();
});

initGame();

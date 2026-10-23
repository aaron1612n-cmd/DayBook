import Foundation

struct Quote {
    let text: String
    let author: String
}

/// Everything here rotates by day number, so it changes daily and is the
/// same all day long.
enum DailyContent {
    static func quote(for date: Date) -> Quote {
        quotes[pick(date, quotes.count, salt: 0)]
    }

    static func fact(for date: Date) -> String {
        facts[pick(date, facts.count, salt: 3)]
    }

    static func prompt(for date: Date) -> String {
        prompts[pick(date, prompts.count, salt: 5)]
    }

    static func challenge(for date: Date) -> String {
        challenges[pick(date, challenges.count, salt: 11)]
    }

    private static func pick(_ date: Date, _ count: Int, salt: Int) -> Int {
        let n = GreetingEngine.dayNumber(date) + salt
        return ((n * 7) % count + count) % count
    }

    static let quotes: [Quote] = [
        Quote(text: "How we spend our days is, of course, how we spend our lives.", author: "Annie Dillard"),
        Quote(text: "Well begun is half done.", author: "Aristotle"),
        Quote(text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt"),
        Quote(text: "The secret of getting ahead is getting started.", author: "Mark Twain"),
        Quote(text: "Simplicity is the ultimate sophistication.", author: "Leonardo da Vinci"),
        Quote(text: "It always seems impossible until it's done.", author: "Nelson Mandela"),
        Quote(text: "Whatever you are, be a good one.", author: "Abraham Lincoln"),
        Quote(text: "Little by little, one travels far.", author: "J.R.R. Tolkien"),
        Quote(text: "Act as if what you do makes a difference. It does.", author: "William James"),
        Quote(text: "Nothing will work unless you do.", author: "Maya Angelou"),
        Quote(text: "The best way out is always through.", author: "Robert Frost"),
        Quote(text: "Done is better than perfect.", author: "Sheryl Sandberg"),
        Quote(text: "You miss 100% of the shots you don't take.", author: "Wayne Gretzky"),
        Quote(text: "What we do every day matters more than what we do once in a while.", author: "Gretchen Rubin"),
        Quote(text: "Be so good they can't ignore you.", author: "Steve Martin"),
        Quote(text: "Stay hungry, stay foolish.", author: "Stewart Brand"),
        Quote(text: "Make each day your masterpiece.", author: "John Wooden"),
        Quote(text: "Doubt kills more dreams than failure ever will.", author: "Suzy Kassem"),
        Quote(text: "If you're going through hell, keep going.", author: "Winston Churchill"),
        Quote(text: "The man who moves a mountain begins by carrying away small stones.", author: "Confucius"),
        Quote(text: "Today is the oldest you've ever been, and the youngest you'll ever be again.", author: "Eleanor Roosevelt"),
        Quote(text: "Start where you are. Use what you have. Do what you can.", author: "Arthur Ashe"),
        Quote(text: "We are what we repeatedly do.", author: "Will Durant"),
        Quote(text: "A year from now you may wish you had started today.", author: "Karen Lamb"),
        Quote(text: "The only way to do great work is to love what you do.", author: "Steve Jobs"),
        Quote(text: "Keep your face always toward the sunshine.", author: "Walt Whitman"),
        Quote(text: "Happiness is not something ready made. It comes from your own actions.", author: "Dalai Lama"),
        Quote(text: "Hard choices, easy life. Easy choices, hard life.", author: "Jerzy Gregorek"),
        Quote(text: "Rest is not idleness.", author: "John Lubbock"),
        Quote(text: "The days are long but the years are short.", author: "Gretchen Rubin"),
        Quote(text: "Fall seven times, stand up eight.", author: "Japanese proverb"),
        Quote(text: "You don't have to see the whole staircase, just take the first step.", author: "Martin Luther King Jr."),
        Quote(text: "Discipline is choosing between what you want now and what you want most.", author: "Abraham Lincoln (attributed)"),
        Quote(text: "Small deeds done are better than great deeds planned.", author: "Peter Marshall"),
        Quote(text: "Be curious, not judgmental.", author: "Walt Whitman (attributed)"),
        Quote(text: "Energy and persistence conquer all things.", author: "Benjamin Franklin"),
        Quote(text: "Comparison is the thief of joy.", author: "Theodore Roosevelt"),
        Quote(text: "Turn your wounds into wisdom.", author: "Oprah Winfrey"),
        Quote(text: "Not all those who wander are lost.", author: "J.R.R. Tolkien"),
        Quote(text: "Dream big. Start small. Act now.", author: "Robin Sharma"),
        Quote(text: "Opportunities don't happen. You create them.", author: "Chris Grosser"),
        Quote(text: "Life is 10% what happens to you and 90% how you react to it.", author: "Charles R. Swindoll"),
        Quote(text: "Everything you can imagine is real.", author: "Pablo Picasso"),
        Quote(text: "Slow progress is still progress.", author: "Unknown"),
        Quote(text: "The future depends on what you do today.", author: "Mahatma Gandhi"),
        Quote(text: "Go as far as you can see; when you get there, you'll see further.", author: "Thomas Carlyle"),
        Quote(text: "Don't count the days. Make the days count.", author: "Muhammad Ali"),
    ]

    static let facts: [String] = [
        "Octopuses have three hearts and blue blood.",
        "Honey never spoils. Edible honey has been found in 3,000-year-old Egyptian tombs.",
        "Bananas are berries. Strawberries aren't.",
        "A day on Venus is longer than its year.",
        "Wombat poop is cube-shaped.",
        "The Eiffel Tower grows about 15 cm taller in summer heat.",
        "Sharks existed before trees did.",
        "There are more possible chess games than atoms in the observable universe.",
        "Sea otters hold hands while they sleep so they don't drift apart.",
        "A group of flamingos is called a flamboyance.",
        "Your brain uses about 20% of your body's energy.",
        "The shortest war in history lasted around 38 minutes.",
        "Hot water can freeze faster than cold water. It's called the Mpemba effect.",
        "Cows have best friends and get stressed when separated.",
        "The inventor of the Pringles can was buried in one.",
        "Scotland's national animal is the unicorn.",
        "A bolt of lightning is about five times hotter than the surface of the sun.",
        "Butterflies taste with their feet.",
        "The dot over an i or j is called a tittle.",
        "Sloths can hold their breath longer than dolphins.",
        "There's enough DNA in your body to stretch to Pluto and back several times.",
        "The first oranges weren't orange. They were green.",
        "Koalas have fingerprints almost identical to humans'.",
        "Neptune has only finished one orbit since it was discovered in 1846.",
        "A jiffy is an actual unit of time: 1/100th of a second.",
        "Peanuts aren't nuts. They're legumes.",
        "Some turtles can breathe through their butts.",
        "The moon has moonquakes.",
        "An ostrich's eye is bigger than its brain.",
        "Water makes up about 60% of your body.",
        "Apple's first logo showed Isaac Newton under a tree.",
        "The heart of a blue whale is about the size of a small car.",
        "Humans share about 60% of their DNA with bananas.",
        "Venus is the only planet that spins clockwise.",
        "Crows can recognise human faces and hold grudges.",
        "The longest hiccup attack lasted 68 years.",
        "A single cloud can weigh more than a million pounds.",
        "Your nose can remember around 50,000 different scents.",
        "Avocados are a single-seeded berry.",
        "The word 'robot' comes from the Czech word for forced labour.",
    ]

    static let prompts: [String] = [
        "What made you smile today?",
        "What's one thing you'd do differently?",
        "Who did you talk to today?",
        "What are you looking forward to?",
        "What did you learn today?",
        "What drained you, and what charged you?",
        "Describe today in three words.",
        "What are you grateful for right now?",
        "What's on your mind that you haven't said out loud?",
        "What was the best thing you ate today?",
        "What would make tomorrow great?",
        "What's a small win from today?",
    ]

    static let challenges: [String] = [
        "Walk 10 minutes without your phone.",
        "Text someone you haven't talked to in a while.",
        "Drink a glass of water right now.",
        "Tidy one surface. Just one.",
        "Go to bed 30 minutes earlier tonight.",
        "Listen to an album start to finish.",
        "Do 20 push-ups, any way you can.",
        "Write down three things you're grateful for.",
        "Eat one meal without a screen.",
        "Learn one word in another language.",
        "Stretch for five minutes.",
        "Compliment someone for real.",
        "Take a photo of something beautiful.",
        "Read ten pages of anything.",
        "Delete five apps or photos you don't need.",
        "Step outside and look at the sky for a minute.",
    ]
}

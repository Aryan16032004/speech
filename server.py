from flask import Flask, request, jsonify
import spacy

app = Flask(__name__)
nlp = spacy.load("en_core_web_sm")

def extract_actions(text):
    doc = nlp(text)
    actions = []
    dates = []

    for ent in doc.ents:
        if ent.label_ in ["DATE", "TIME"]:
            dates.append(ent.text)

    for token in doc:
        if token.dep_ in ["xcomp", "ROOT"] and token.pos_ in ["VERB"]:
            actions.append(token.text)

    return {"tasks": actions, "dates": dates}

@app.route('/process', methods=['POST'])
def process_text():
    data = request.json
    text = data.get("text", "")
    result = extract_actions(text)
    return jsonify(result)

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)

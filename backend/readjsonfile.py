import json
import time

start = time.time()

# Open and read JSON file
with open('stationnement-voie-publique-emplacements.json', 'r', encoding='utf-8') as file:
    data = json.load(file)

print(data) # Outputs the parsed Python object
end = time.time()
print(f'Elapsed: {end - start:.2f} seconds')
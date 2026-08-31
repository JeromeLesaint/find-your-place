import requests
from pymongo import ReplaceOne


DATASET_ID = "stationnement-en-ouvrage"

API_URL = (
    "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/"
    f"{DATASET_ID}/records"
)

TIMEOUT = (10, 60)


def recuperer_parkings():
    """Récupère tous les parkings depuis Paris Open Data."""

    parkings = []
    limit = 100
    offset = 0

    while True:
        response = requests.get(
            API_URL,
            params={"limit": limit, "offset": offset},
            timeout=TIMEOUT,
        )
        response.raise_for_status()

        resultats = response.json().get("results", [])
        if not resultats:
            break

        parkings.extend(resultats)

        if len(resultats) < limit:
            break

        offset += limit

    print(f"{len(parkings)} parking(s) récupéré(s).")
    return parkings


def normaliser_parking(parking):
    """Construit un document parking lisible et organisé pour l'application."""

    return {
        "type_donnee": "parking",
        "identifiant_parking": parking.get("id"),
        "informations_generales": {
            "nom": parking.get("nom"),
            "adresse": parking.get("adresse"),
            "arrondissement": parking.get("insee"),
            "exploitant": parking.get("deleg"),
            "utilisateurs_autorises": parking.get("type_usagers"),
            "type_de_parking": parking.get("type_ouvrage"),
            "horaires": parking.get("horaire_na"),
            "hauteur_maximale": parking.get("hauteur_max"),
            "vehicules_acceptes_a_entree": parking.get("veh_tremie"),
            "telephone": parking.get("tel"),
            "site_internet": parking.get("url"),
        },
        "capacites": {
            "voitures": parking.get("nb_places"),
            "personnes_a_mobilite_reduite": parking.get("nb_pmr"),
            "vehicules_electriques": parking.get("nb_voitures_electriques"),
            "velos": parking.get("nb_velo"),
            "deux_roues_motorises": parking.get("nb_2_rm"),
        },
        "tarifs": {
            "voitures": {
                "quinze_minutes": parking.get("tf_15mn_e"),
                "trente_minutes": parking.get("tf_30mn_e"),
                "une_heure": parking.get("tarif_1h"),
                "une_heure_trente": parking.get("tf_1h30_e"),
                "deux_heures": parking.get("tarif_2h"),
                "trois_heures": parking.get("tarif_3h"),
                "quatre_heures": parking.get("tarif_4h"),
                "sept_heures": parking.get("tf_7h_e"),
                "huit_heures": parking.get("tf_8h_e"),
                "neuf_heures": parking.get("tf_9h_e"),
                "dix_heures": parking.get("tf_10h_e"),
                "onze_heures": parking.get("tf_11h_e"),
                "douze_heures": parking.get("tf_12h_e"),
                "vingt_quatre_heures": parking.get("tarif_24h"),
            },
            "motos": {
                "quinze_minutes": parking.get("tf_15mn_mo"),
                "trente_minutes": parking.get("tf_30mn_mo"),
                "une_heure": parking.get("tmoto_1ehe"),
                "vingt_quatre_heures": parking.get("tf_24h_mot"),
            },
            "velos": {"journee": parking.get("tvelo_1j_e")},
            "personnes_a_mobilite_reduite": {"tarif": parking.get("tarif_pmr")},
        },
        "abonnements": {
            "voitures": {
                "residents": {
                    "disponible": parking.get("abo_resident"),
                    "un_mois": parking.get("tf_res_1me"),
                    "un_an": parking.get("tf_res_1ae"),
                },
                "non_residents": {
                    "disponible": parking.get("abo_non_resident"),
                    "un_mois": parking.get("ab_1m_e"),
                    "un_an": parking.get("ab_1a_e"),
                    "un_an_tarif_reduit": parking.get("ab_1a_patt"),
                    "un_mois_parc_relais": parking.get("ab_1m_rela"),
                },
                "parc_relais": {
                    "disponible": parking.get("tarif_pr"),
                    "un_an_tarif_minimum": parking.get("pr_1a_mine"),
                    "un_an_tarif_maximum": parking.get("pr_1a_maxe"),
                },
            },
            "motos": {
                "un_mois": parking.get("abmoto_1me"),
                "un_trimestre": parking.get("abmoto_1te"),
                "un_an": parking.get("abmoto_1ae"),
                "parc_relais": parking.get("tf_pr_moto"),
                "parc_relais_un_an_tarif_minimum": parking.get("pr_1a_minm"),
                "parc_relais_un_an_tarif_maximum": parking.get("pr_1a_maxm"),
                "resident_un_mois": parking.get("tf_res_mo"),
                "resident_un_an": parking.get("tf_res_1am"),
            },
            "personnes_a_mobilite_reduite": {
                "un_mois": parking.get("abpmr_1m_e"),
                "un_trimestre": parking.get("abpmr_1t_e"),
                "un_an": parking.get("abpmr_1a_e"),
            },
            "vehicules_electriques": {
                "un_mois": parking.get("abve_1m_e"),
                "un_trimestre": parking.get("abve_1t_e"),
                "un_an": parking.get("abve_1a_e"),
            },
            "velos": {
                "un_mois": parking.get("tvelo_1m_e"),
                "un_an": parking.get("tvelo_1a_e"),
                "velo_cargo_un_jour": parking.get("tvelocg_1j_e"),
                "velo_cargo_un_mois": parking.get("tvelocg_1m_e"),
                "velo_cargo_un_an": parking.get("tvelocg_1a_e"),
            },
            "pass_deux_roues_motorises": {
                "disponible": parking.get("pass_2rm"),
                "une_heure": parking.get("pass_2rm_1h"),
                "un_mois": parking.get("pass_2rm_1m"),
                "trois_mois": parking.get("pass_2rm_3m"),
                "un_an": parking.get("pass_2rm_1a"),
            },
        },
        "geolocalisation": {
            "forme_geographique": parking.get("geo_shape"),
            "point_geographique": parking.get("geo_point_2d"),
        },
    }


def est_parc_amodie(parking):
    """Indique si le parking est réservé à des amodiataires."""

    return str(parking.get("parc_amod", "")).strip().upper() == "OUI"


def import_parkings(collection):
    """Remplace les parkings par la sélection utile à l'application."""

    collection.create_index([("geolocalisation.forme_geographique.geometry", "2dsphere")])

    operations = []
    amodies_ignores = 0

    resultat_suppression = collection.delete_many(
        {"type_donnee": "parking", "parc_amod": {"$in": [True, 1, "1", "oui", "OUI"]}}
    )

    for parking in recuperer_parkings():
        if est_parc_amodie(parking):
            amodies_ignores += 1
            continue

        parking_normalise = normaliser_parking(parking)
        parking_id = parking_normalise.get("identifiant_parking")

        if not parking_id:
            continue

        operations.append(
            ReplaceOne(
                {"type_donnee": "parking", "identifiant_parking": parking_id},
                parking_normalise,
                upsert=True,
            )
        )

    if not operations:
        print("Aucun parking à importer.")
        return

    resultat = collection.bulk_write(operations, ordered=False)
    print(f"{len(operations)} parking(s) traité(s).")
    print(f"{amodies_ignores} parking(s) amodié(s) ignoré(s).")
    print(f"{resultat_suppression.deleted_count} ancien(s) parking(s) amodié(s) supprimé(s).")
    print(f"{resultat.upserted_count} parking(s) ajouté(s).")
    print(f"{resultat.modified_count} parking(s) mis à jour.")

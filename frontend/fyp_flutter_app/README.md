# fyp_flutter_app

Application mobile en Flutter

## Configuration requise

- Flutter 3.38.9
- Android SDK
- Java SDK 21

## Variables d'environnement

Ces variables d'environnement doivent être présentes

- ANDROID_HOME 
- JAVA_HOME
- répertoire bin de flutter dans le path

## Installer les packages flutter

```bash
flutter pub get
```

## Créer un .env

A la racine du projet, créer un fichier **.env** dont le contenu sera le suivant (vos informations à remplacer) :

```bash
API_URL=http://192.168.1.81:8000
SECRET_PHRASE=MySuperSecretPhrase123!
```

L'**API_URL** correspond à l'adresse IP de votre machine sur le port 8000 (backend)

Pour trouver votre IP sur Windows :
```bash
ipconfig /all
```

## Quota d'utilisation de Google Maps

L'application utilise Google Maps, le quota d'utilisation gratuite est fixé à 10000 requêtes par mois.

## Tester l'application

Sur un smartphone sur Android, il faut activer le mode développeur du téléphone (appuyez 10 fois sur le numéro de version android dans les paramètres du téléphone).
Activer ensuite le mode débogage USB.
Connecter votre ordinateur à votre téléphone en USB avec un câble gérant le MTP (transfert de datas).
Connecter votre smartphone au même réseau que votre PC (même réseau WI-FI) pour que l'application puisse faire appel au backend.

En ouvrant VSC, il faut se positionner sur le fichier **main.dart** dans **lib** et faire un run.
Dans les commandes et afin de debugger, on peut lancer **Open Dart DevTools in browser**

## Bugs et améliorations

- Rafraichissement des CircularMenuItem après ajout d'un nouveau véhicule
- Positionner la map sur la localisation (désactivée pour les tests et le développement)
- Actualisation de la position en temps réel (désactivée)
- Design de la page informations
- Actualisation des emplacements selon le véhicule choisi
- Ajout de tooltips sur les items du CircularMenu
- Ajout des toutes les informations sur les tooltips des markers google




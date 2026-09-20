# Car Pool local API

This is a zero-dependency development API for the Flutter app. It stores local test data in `data.json`, created automatically the first time it receives a write request.

Start it from this folder:

```powershell
npm start
```

The API is available at `http://localhost:3000/api`.

This server is intended for local development. It does not authenticate requests or validate real student records, so replace it with a secured production backend before deploying.

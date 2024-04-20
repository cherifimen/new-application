# Utiliser une image de base avec Node.js
FROM node:14-alpine

# Créer le répertoire de travail
WORKDIR /app

# Copier les fichiers de l'application
COPY package*.json ./

#Install project dependencies
RUN npm install

# Copy the entire project directory to the working directory
COPY . .

# Expose the port that the application listens on
EXPOSE 3700

# Set the command to run the application
CMD ["node", "app.js"]

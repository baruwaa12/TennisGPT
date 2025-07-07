# Deploying TennisGPT Backend to Render.com

## 🚀 Quick Start Guide

### Step 1: Prepare Your Repository

Make sure your GitHub repository has this structure:
```
TennisGPT/
├── backend/
│   ├── main.py
│   ├── requirements.txt
│   ├── render.yaml
│   └── services/
└── mobile/
```

### Step 2: Deploy to Render.com

1. **Go to [Render.com](https://render.com)** and sign up/login
2. **Click "New +"** → **"Web Service"**
3. **Connect your GitHub repository**
4. **Configure the service:**
   - **Name**: `tennisgpt-backend`
   - **Environment**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Root Directory**: `backend` (important!)

### Step 3: Environment Variables (Optional)

If you need environment variables (like API keys), add them in Render dashboard:
- Go to your service → **Environment** tab
- Add variables like:
  - `OPENAI_API_KEY`
  - `DATABASE_URL`
  - `ENVIRONMENT=production`

### Step 4: Deploy

Click **"Create Web Service"** and wait for deployment!

## ✅ What You Get

- **Free tier**: 750 hours/month
- **Automatic HTTPS**: Your API will be at `https://your-app-name.onrender.com`
- **Custom domains**: Add your own domain later
- **Auto-deploy**: Updates automatically when you push to GitHub
- **Logs**: View real-time logs in the dashboard

## 🔧 Configuration Details

### render.yaml (Blueprint)
The `render.yaml` file I created will automatically configure everything when you connect your repo.

### main.py
Your FastAPI app is already configured to work with Render:
- Uses `$PORT` environment variable
- CORS configured for Flutter app
- Health check endpoints ready

### requirements.txt
Contains all necessary dependencies for production.

## 🌐 Your API Endpoints

Once deployed, your API will be available at:
- **Health Check**: `https://your-app-name.onrender.com/`
- **API Health**: `https://your-app-name.onrender.com/api/health`
- **Chat Endpoint**: `https://your-app-name.onrender.com/api/chat`

## 📱 Update Your Flutter App

After deployment, update your Flutter app's API base URL to:
```dart
const String baseUrl = 'https://your-app-name.onrender.com';
```

## 🚨 Important Notes

### Free Tier Limitations:
- **Sleep after 15 minutes** of inactivity
- **Cold start** when waking up (first request may be slow)
- **750 hours/month** (about 31 days)

### For Production:
- Consider upgrading to **Paid plan** ($7/month) for:
  - Always-on service (no sleep)
  - Better performance
  - More resources

## 🔍 Troubleshooting

### Common Issues:

1. **Build fails**: Check `requirements.txt` has all dependencies
2. **Port issues**: Make sure using `$PORT` in start command
3. **Import errors**: Verify all files are in the `backend/` directory
4. **Cold starts**: Normal for free tier, first request may take 10-30 seconds

### Debug Commands:
- Check **Logs** in Render dashboard
- Test locally: `uvicorn main:app --reload`
- Verify requirements: `pip install -r requirements.txt`

## 🎯 Next Steps

1. **Deploy to Render.com** using the steps above
2. **Test your API endpoints**
3. **Update Flutter app** with new API URL
4. **Add custom domain** if needed
5. **Set up environment variables** for production

## 💡 Pro Tips

- **Monitor logs** in Render dashboard for debugging
- **Use environment variables** for sensitive data (API keys)
- **Test locally first** before deploying
- **Consider paid plan** for better performance in production 
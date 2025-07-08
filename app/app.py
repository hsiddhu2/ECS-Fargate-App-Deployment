from flask import Flask, jsonify 
import os 

app = Flask(__name__)

@app.route('/')
def hello_world():
    return jsonify({
        'message': os.getenv('MESSAGE', 'Hello World from ECS Fargate'),
        'version': os.getenv('VERSION', '1.0.0'),
        'environment': os.getenv('ENVIRONMENT', 'development'),
        'container_id': os.getenv('HOSTNAME', 'unknown'),
        'region': os.getenv('AWS_REGION', 'us-west-2')
    })

@app.route('/health')
def health_check():
    return jsonify({'status': 'healthy'}), 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port)

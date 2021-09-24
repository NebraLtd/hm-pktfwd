from pktfwd.pktfwd_app import PktfwdApp

def main():
    pktfwd_app = PktfwdApp()
    try:
        pktfwd_app.start()
    except Exception:
        # logger.exception('__main__ failed for unknown reason')
        pktfwd_app.stop()
        
if __name__ == "__main__":
    main()